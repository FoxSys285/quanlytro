create table if not exists public.subscription_payment_settings (
  id boolean primary key default true check (id is true),
  bank_name text not null,
  bank_bin text not null,
  account_name text not null,
  account_number text not null,
  instructions text not null default '',
  updated_by text not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.subscription_orders (
  id uuid primary key default gen_random_uuid(),
  legacy_id text unique,
  landlord_uid text not null,
  landlord_name text not null,
  landlord_email text not null default '',
  plan_id text not null check (plan_id in ('go', 'plus', 'ultra')),
  plan_name text not null,
  amount integer not null check (amount > 0),
  payment_reference text not null unique,
  payment_bank_name text not null,
  payment_bank_bin text not null,
  payment_account_name text not null,
  payment_account_number text not null,
  payment_instructions text not null default '',
  status text not null check (status in (
    'awaiting_payment', 'submitted', 'approved', 'rejected', 'cancelled'
  )),
  payment_note text not null default '',
  admin_note text not null default '',
  created_at timestamptz not null default now(),
  submitted_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by text,
  starts_at timestamptz,
  expires_at timestamptz
);

create index if not exists subscription_orders_landlord_created_idx
  on public.subscription_orders (landlord_uid, created_at desc);
create index if not exists subscription_orders_status_created_idx
  on public.subscription_orders (status, created_at desc);
create unique index if not exists subscription_orders_one_open_per_landlord_idx
  on public.subscription_orders (landlord_uid)
  where status in ('awaiting_payment', 'submitted');

create table if not exists public.sepay_transactions (
  transaction_hash text primary key,
  transaction_id text not null,
  order_id uuid references public.subscription_orders(id),
  payment_reference text,
  account_number text not null default '',
  transfer_amount bigint not null default 0,
  content text not null default '',
  transfer_type text not null default '',
  result text not null check (result in ('processing', 'approved', 'unmatched')),
  received_at timestamptz not null default now()
);

create table if not exists public.sepay_unmatched_transactions (
  transaction_hash text primary key references public.sepay_transactions(transaction_hash),
  transaction_id text not null,
  account_number text not null default '',
  transfer_amount bigint not null default 0,
  content text not null default '',
  transfer_type text not null default '',
  reason text not null,
  received_at timestamptz not null default now()
);

create index if not exists sepay_unmatched_received_idx
  on public.sepay_unmatched_transactions (received_at desc);

create table if not exists public.subscription_legacy_migrations (
  id text primary key,
  completed_at timestamptz not null default now()
);

alter table public.subscription_payment_settings enable row level security;
alter table public.subscription_orders enable row level security;
alter table public.sepay_transactions enable row level security;
alter table public.sepay_unmatched_transactions enable row level security;
alter table public.subscription_legacy_migrations enable row level security;

revoke all on public.subscription_payment_settings from anon, authenticated;
revoke all on public.subscription_orders from anon, authenticated;
revoke all on public.sepay_transactions from anon, authenticated;
revoke all on public.sepay_unmatched_transactions from anon, authenticated;
revoke all on public.subscription_legacy_migrations from anon, authenticated;
grant all on public.subscription_payment_settings to service_role;
grant all on public.subscription_orders to service_role;
grant all on public.sepay_transactions to service_role;
grant all on public.sepay_unmatched_transactions to service_role;
grant all on public.subscription_legacy_migrations to service_role;

create or replace function public.process_sepay_subscription_transaction(
  p_transaction_hash text,
  p_transaction_id text,
  p_account_number text,
  p_transfer_amount bigint,
  p_transfer_type text,
  p_payment_reference text,
  p_content text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_settings public.subscription_payment_settings%rowtype;
  v_order public.subscription_orders%rowtype;
  v_reason text;
  v_starts_at timestamptz;
  v_expires_at timestamptz;
  v_rows integer;
begin
  insert into public.sepay_transactions (
    transaction_hash, transaction_id, payment_reference, account_number,
    transfer_amount, content, transfer_type, result
  ) values (
    p_transaction_hash, p_transaction_id, p_payment_reference,
    coalesce(p_account_number, ''), greatest(coalesce(p_transfer_amount, 0), 0),
    coalesce(p_content, ''), coalesce(p_transfer_type, ''), 'processing'
  ) on conflict (transaction_hash) do nothing;
  get diagnostics v_rows = row_count;

  if v_rows = 0 then
    return jsonb_build_object('result', 'duplicate');
  end if;

  select * into v_settings
    from public.subscription_payment_settings where id = true;

  if not found then
    v_reason := 'receiving_account_not_configured';
  elsif lower(trim(coalesce(p_transfer_type, ''))) <> 'in' then
    v_reason := 'not_incoming';
  elsif trim(coalesce(p_account_number, '')) = ''
      or trim(p_account_number) <> trim(v_settings.account_number) then
    v_reason := 'receiving_account_mismatch';
  elsif p_payment_reference is null or trim(p_payment_reference) = '' then
    v_reason := 'payment_reference_not_found';
  elsif coalesce(p_transfer_amount, 0) <= 0 then
    v_reason := 'invalid_amount';
  end if;

  if v_reason is not null then
    insert into public.sepay_unmatched_transactions (
      transaction_hash, transaction_id, account_number, transfer_amount,
      content, transfer_type, reason
    ) values (
      p_transaction_hash, p_transaction_id, coalesce(p_account_number, ''),
      greatest(coalesce(p_transfer_amount, 0), 0), coalesce(p_content, ''),
      coalesce(p_transfer_type, ''), v_reason
    );
    update public.sepay_transactions set result = 'unmatched'
      where transaction_hash = p_transaction_hash;
    return jsonb_build_object('result', 'unmatched', 'reason', v_reason);
  end if;

  select * into v_order
    from public.subscription_orders
    where payment_reference = p_payment_reference
    for update;

  if not found then
    v_reason := 'order_not_found';
  elsif v_order.amount <> p_transfer_amount
      or (case v_order.plan_id
        when 'go' then 39000
        when 'plus' then 99000
        when 'ultra' then 199000
        else -1
      end) <> p_transfer_amount then
    v_reason := 'amount_mismatch';
  elsif v_order.status not in ('awaiting_payment', 'submitted') then
    v_reason := 'order_not_payable';
  end if;

  if v_reason is not null then
    insert into public.sepay_unmatched_transactions (
      transaction_hash, transaction_id, account_number, transfer_amount,
      content, transfer_type, reason
    ) values (
      p_transaction_hash, p_transaction_id, coalesce(p_account_number, ''),
      greatest(coalesce(p_transfer_amount, 0), 0), coalesce(p_content, ''),
      coalesce(p_transfer_type, ''), v_reason
    );
    update public.sepay_transactions set result = 'unmatched'
      where transaction_hash = p_transaction_hash;
    return jsonb_build_object('result', 'unmatched', 'reason', v_reason);
  end if;

  select greatest(now(), coalesce(max(expires_at), now())) into v_starts_at
    from public.subscription_orders
    where landlord_uid = v_order.landlord_uid
      and id <> v_order.id
      and status = 'approved'
      and expires_at > now();
  v_expires_at := v_starts_at + interval '30 days';

  update public.subscription_orders set
    status = 'approved',
    admin_note = 'Đã tự động đối soát qua SePay.',
    reviewed_by = 'sepay-webhook',
    reviewed_at = now(),
    starts_at = v_starts_at,
    expires_at = v_expires_at
  where id = v_order.id;

  update public.sepay_transactions set result = 'approved', order_id = v_order.id
    where transaction_hash = p_transaction_hash;
  return jsonb_build_object(
    'result', 'approved', 'orderId', v_order.id,
    'startsAt', v_starts_at, 'expiresAt', v_expires_at
  );
end;
$$;

create or replace function public.review_subscription_order(
  p_order_id uuid,
  p_admin_uid text,
  p_approve boolean,
  p_note text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.subscription_orders%rowtype;
  v_starts_at timestamptz;
  v_expires_at timestamptz;
begin
  if length(trim(coalesce(p_note, ''))) > 500
      or (not p_approve and length(trim(coalesce(p_note, ''))) = 0) then
    raise exception 'Ghi chú từ chối không hợp lệ.' using errcode = '22023';
  end if;

  select * into v_order from public.subscription_orders
    where id = p_order_id for update;
  if not found or v_order.status <> 'submitted' then
    raise exception 'Yêu cầu này đã được xử lý hoặc chưa gửi xác nhận.'
      using errcode = 'P0002';
  end if;

  if p_approve then
    select greatest(now(), coalesce(max(expires_at), now())) into v_starts_at
      from public.subscription_orders
      where landlord_uid = v_order.landlord_uid
        and id <> v_order.id
        and status = 'approved'
        and expires_at > now();
    v_expires_at := v_starts_at + interval '30 days';
  end if;

  update public.subscription_orders set
    status = case when p_approve then 'approved' else 'rejected' end,
    admin_note = trim(coalesce(p_note, '')),
    reviewed_by = p_admin_uid,
    reviewed_at = now(),
    starts_at = v_starts_at,
    expires_at = v_expires_at
  where id = v_order.id returning * into v_order;
  return to_jsonb(v_order);
end;
$$;

create or replace function public.import_legacy_subscription_data(
  p_settings jsonb,
  p_orders jsonb,
  p_unmatched jsonb
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order jsonb;
  v_transaction jsonb;
  v_rows integer;
begin
  insert into public.subscription_legacy_migrations(id)
    values ('firestore-subscriptions-v1') on conflict do nothing;
  get diagnostics v_rows = row_count;
  if v_rows = 0 then
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
      coalesce(v_order->>'paymentInstructions', ''),
      case when v_order->>'status' in ('awaiting_payment', 'submitted', 'approved', 'rejected', 'cancelled')
        then v_order->>'status' else 'awaiting_payment' end,
      coalesce(v_order->>'paymentNote', ''), coalesce(v_order->>'adminNote', ''),
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
      v_transaction->>'id', coalesce(v_transaction->>'transactionId', v_transaction->>'id'),
      coalesce(v_transaction->>'accountNumber', ''),
      greatest(coalesce(nullif(v_transaction->>'transferAmount', '')::bigint, 0), 0),
      coalesce(v_transaction->>'content', ''), coalesce(v_transaction->>'transferType', ''),
      'unmatched', coalesce(nullif(v_transaction->>'receivedAt', '')::timestamptz, now())
    ) on conflict do nothing;
    insert into public.sepay_unmatched_transactions (
      transaction_hash, transaction_id, account_number, transfer_amount,
      content, transfer_type, reason, received_at
    ) values (
      v_transaction->>'id', coalesce(v_transaction->>'transactionId', v_transaction->>'id'),
      coalesce(v_transaction->>'accountNumber', ''),
      greatest(coalesce(nullif(v_transaction->>'transferAmount', '')::bigint, 0), 0),
      coalesce(v_transaction->>'content', ''), coalesce(v_transaction->>'transferType', ''),
      coalesce(v_transaction->>'reason', 'legacy-unmatched'),
      coalesce(nullif(v_transaction->>'receivedAt', '')::timestamptz, now())
    ) on conflict do nothing;
  end loop;

  return jsonb_build_object('imported', true);
end;
$$;

revoke all on function public.process_sepay_subscription_transaction(text, text, text, bigint, text, text, text) from public, anon, authenticated;
revoke all on function public.review_subscription_order(uuid, text, boolean, text) from public, anon, authenticated;
revoke all on function public.import_legacy_subscription_data(jsonb, jsonb, jsonb) from public, anon, authenticated;
grant execute on function public.process_sepay_subscription_transaction(text, text, text, bigint, text, text, text) to service_role;
grant execute on function public.review_subscription_order(uuid, text, boolean, text) to service_role;
grant execute on function public.import_legacy_subscription_data(jsonb, jsonb, jsonb) to service_role;
