create or replace function public.simulate_subscription_payment(
  p_landlord_uid text,
  p_landlord_name text,
  p_landlord_email text,
  p_plan_id text,
  p_order_id uuid
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.subscription_orders%rowtype;
  v_amount integer;
  v_plan_name text;
  v_starts_at timestamptz;
  v_expires_at timestamptz;
  v_payment_note text := 'Thanh toán giả lập thành công; không phát sinh giao dịch thật.';
  v_admin_note text := 'Giao dịch giả lập cho mục đích trình bày đồ án.';
begin
  if coalesce(trim(p_landlord_uid), '') = '' then
    raise exception 'Tài khoản chủ trọ không hợp lệ.' using errcode = '22023';
  end if;

  if p_order_id is not null then
    select * into v_order
      from public.subscription_orders
      where id = p_order_id and landlord_uid = p_landlord_uid
      for update;

    if not found then
      raise exception 'Không tìm thấy yêu cầu đăng ký gói.' using errcode = 'P0002';
    end if;
    if v_order.status not in ('awaiting_payment', 'submitted') then
      raise exception 'Yêu cầu này đã được xử lý hoặc đã bị hủy.' using errcode = 'P0002';
    end if;

    v_amount := v_order.amount;
    v_plan_name := v_order.plan_name;
  else
    v_amount := case p_plan_id
      when 'go' then 39000
      when 'plus' then 99000
      when 'ultra' then 199000
      else null
    end;
    if v_amount is null then
      raise exception 'Gói dịch vụ không hợp lệ.' using errcode = '22023';
    end if;
    v_plan_name := case p_plan_id
      when 'go' then 'Go'
      when 'plus' then 'Plus'
      when 'ultra' then 'Ultra'
    end;
  end if;

  select greatest(now(), coalesce(max(expires_at), now())) into v_starts_at
    from public.subscription_orders
    where landlord_uid = p_landlord_uid
      and id is distinct from p_order_id
      and status = 'approved'
      and expires_at > now();
  v_expires_at := v_starts_at + interval '30 days';

  if p_order_id is null then
    insert into public.subscription_orders (
      landlord_uid, landlord_name, landlord_email, plan_id, plan_name,
      amount, payment_reference, payment_bank_name, payment_bank_bin,
      payment_account_name, payment_account_number, payment_instructions,
      status, payment_note, admin_note, submitted_at, reviewed_at,
      reviewed_by, starts_at, expires_at
    ) values (
      p_landlord_uid, coalesce(nullif(trim(p_landlord_name), ''), 'Chủ trọ'),
      coalesce(trim(p_landlord_email), ''), p_plan_id, v_plan_name,
      v_amount,
      'DEMO' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10)),
      'Mô phỏng', '000000', 'TÀI KHOẢN MÔ PHỎNG', '0000000000',
      'Chỉ dùng cho đồ án; không chuyển tiền.',
      'approved', v_payment_note, v_admin_note, now(), now(),
      'demo-payment', v_starts_at, v_expires_at
    ) returning * into v_order;
  else
    update public.subscription_orders set
      payment_reference = 'DEMO' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10)),
      payment_bank_name = 'Mô phỏng',
      payment_bank_bin = '000000',
      payment_account_name = 'TÀI KHOẢN MÔ PHỎNG',
      payment_account_number = '0000000000',
      payment_instructions = 'Chỉ dùng cho đồ án; không chuyển tiền.',
      status = 'approved',
      payment_note = v_payment_note,
      admin_note = v_admin_note,
      submitted_at = coalesce(submitted_at, now()),
      reviewed_at = now(),
      reviewed_by = 'demo-payment',
      starts_at = v_starts_at,
      expires_at = v_expires_at
    where id = p_order_id
    returning * into v_order;
  end if;

  return to_jsonb(v_order);
end;
$$;

revoke all on function public.simulate_subscription_payment(text, text, text, text, uuid)
  from public, anon, authenticated;
grant execute on function public.simulate_subscription_payment(text, text, text, text, uuid)
  to service_role;
