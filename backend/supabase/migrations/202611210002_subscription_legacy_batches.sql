drop function if exists public.import_legacy_subscription_data(jsonb, jsonb, jsonb);

create or replace function public.import_legacy_subscription_batch(
  p_settings jsonb,
  p_orders jsonb,
  p_unmatched jsonb,
  p_final boolean
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order jsonb;
  v_transaction jsonb;
  v_status text;
  v_admin_note text;
begin
  if exists (
    select 1 from public.subscription_legacy_migrations
    where id = 'firestore-subscriptions-v1'
  ) then
    return jsonb_build_object('imported', false, 'alreadyImported', true);
  end if;

  if p_settings is not null and jsonb_typeof(p_settings) = 'object'
      and coalesce(p_settings->>'accountNumber', '') <> '' then
    insert into public.subscription_payment_settings (
      id, bank_name, bank_bin, account_name, account_number,
      instructions, updated_by, updated_at
    ) values (
      true, coalesce(p_settings->>'bankName', ''),
      coalesce(p_settings->>'bankBin', ''), coalesce(p_settings->>'accountName', ''),
      p_settings->>'accountNumber', coalesce(p_settings->>'instructions', ''),
      coalesce(p_settings->>'updatedBy', 'legacy-import'),
      coalesce(nullif(p_settings->>'updatedAt', '')::timestamptz, now())
    ) on conflict (id) do nothing;
  end if;

  for v_order in select value from jsonb_array_elements(coalesce(p_orders, '[]'::jsonb))
  loop
    if coalesce(v_order->>'id', '') = ''
        or coalesce(v_order->>'landlordUid', '') = ''
        or coalesce(v_order->>'paymentReference', '') = ''
        or coalesce(v_order->>'planId', '') not in ('go', 'plus', 'ultra') then
      continue;
    end if;

    v_status := case
      when v_order->>'status' in (
        'awaiting_payment', 'submitted', 'approved', 'rejected', 'cancelled'
      ) then v_order->>'status'
      else 'awaiting_payment'
    end;
    v_admin_note := coalesce(v_order->>'adminNote', '');
    if v_status in ('awaiting_payment', 'submitted') and exists (
      select 1 from public.subscription_orders
      where landlord_uid = v_order->>'landlordUid'
        and status in ('awaiting_payment', 'submitted')
        and (legacy_id is null or legacy_id <> v_order->>'id')
    ) then
      v_status := 'cancelled';
      v_admin_note := concat_ws(
        ' · ', nullif(trim(v_admin_note), ''),
        'Đơn cũ được hủy khi chuyển dữ liệu để tránh trùng yêu cầu đang mở.'
      );
    end if;

    insert into public.subscription_orders (
      legacy_id, landlord_uid, landlord_name, landlord_email, plan_id,
      plan_name, amount, payment_reference, payment_bank_name,
      payment_bank_bin, payment_account_name, payment_account_number,
      payment_instructions, status, payment_note, admin_note, created_at,
      submitted_at, reviewed_at, reviewed_by, starts_at, expires_at
    ) values (
      v_order->>'id', v_order->>'landlordUid', coalesce(v_order->>'landlordName', ''),
      coalesce(v_order->>'landlordEmail', ''), v_order->>'planId',
      coalesce(v_order->>'planName', ''), (v_order->>'amount')::integer,
      v_order->>'paymentReference', coalesce(v_order->>'paymentBankName', ''),
      coalesce(v_order->>'paymentBankBin', ''), coalesce(v_order->>'paymentAccountName', ''),
      coalesce(v_order->>'paymentAccountNumber', ''),
      coalesce(v_order->>'paymentInstructions', ''), v_status,
      coalesce(v_order->>'paymentNote', ''), v_admin_note,
      coalesce(nullif(v_order->>'createdAt', '')::timestamptz, now()),
      nullif(v_order->>'submittedAt', '')::timestamptz,
      nullif(v_order->>'reviewedAt', '')::timestamptz,
      nullif(v_order->>'reviewedBy', ''),
      nullif(v_order->>'startsAt', '')::timestamptz,
      nullif(v_order->>'expiresAt', '')::timestamptz
    ) on conflict do nothing;
  end loop;

  for v_transaction in select value from jsonb_array_elements(coalesce(p_unmatched, '[]'::jsonb))
  loop
    if coalesce(v_transaction->>'id', '') = '' then continue; end if;
    insert into public.sepay_transactions (
      transaction_hash, transaction_id, account_number, transfer_amount,
      content, transfer_type, result, received_at
    ) values (
      v_transaction->>'id',
      coalesce(v_transaction->>'transactionId', v_transaction->>'id'),
      coalesce(v_transaction->>'accountNumber', ''),
      greatest(coalesce(nullif(v_transaction->>'transferAmount', '')::bigint, 0), 0),
      coalesce(v_transaction->>'content', ''), coalesce(v_transaction->>'transferType', ''),
      'unmatched', coalesce(nullif(v_transaction->>'receivedAt', '')::timestamptz, now())
    ) on conflict do nothing;
    insert into public.sepay_unmatched_transactions (
      transaction_hash, transaction_id, account_number, transfer_amount,
      content, transfer_type, reason, received_at
    ) values (
      v_transaction->>'id',
      coalesce(v_transaction->>'transactionId', v_transaction->>'id'),
      coalesce(v_transaction->>'accountNumber', ''),
      greatest(coalesce(nullif(v_transaction->>'transferAmount', '')::bigint, 0), 0),
      coalesce(v_transaction->>'content', ''), coalesce(v_transaction->>'transferType', ''),
      coalesce(v_transaction->>'reason', 'legacy-unmatched'),
      coalesce(nullif(v_transaction->>'receivedAt', '')::timestamptz, now())
    ) on conflict do nothing;
  end loop;

  if p_final then
    insert into public.subscription_legacy_migrations(id)
      values ('firestore-subscriptions-v1') on conflict do nothing;
  end if;
  return jsonb_build_object('imported', true, 'complete', p_final);
end;
$$;

revoke all on function public.import_legacy_subscription_batch(jsonb, jsonb, jsonb, boolean)
  from public, anon, authenticated;
grant execute on function public.import_legacy_subscription_batch(jsonb, jsonb, jsonb, boolean)
  to service_role;
