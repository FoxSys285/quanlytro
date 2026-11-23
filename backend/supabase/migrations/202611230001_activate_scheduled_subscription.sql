create or replace function public.activate_scheduled_subscription_order(
  p_landlord_uid text,
  p_order_id uuid
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.subscription_orders%rowtype;
  v_active_plan_id text;
  v_now timestamptz := now();
  v_next_starts_at timestamptz;
  v_queued record;
  v_duration interval;
begin
  if coalesce(trim(p_landlord_uid), '') = '' then
    raise exception 'Tài khoản chủ trọ không hợp lệ.' using errcode = '22023';
  end if;

  perform 1 from public.subscription_orders
    where landlord_uid = p_landlord_uid for update;

  select * into v_order from public.subscription_orders
    where id = p_order_id and landlord_uid = p_landlord_uid;
  if not found
      or v_order.status <> 'approved'
      or v_order.starts_at is null
      or v_order.expires_at is null
      or v_order.starts_at <= v_now
      or v_order.expires_at <= v_now then
    raise exception 'Gói này không còn chờ kích hoạt.' using errcode = 'P0002';
  end if;

  select plan_id into v_active_plan_id
    from public.subscription_orders
    where landlord_uid = p_landlord_uid
      and id <> p_order_id
      and status = 'approved'
      and starts_at <= v_now
      and expires_at > v_now
    order by starts_at desc, reviewed_at desc nulls last, created_at desc
    limit 1;

  if v_active_plan_id = v_order.plan_id then
    raise exception 'Gói đang sử dụng đã cùng loại; hãy chờ đến ngày hết hạn.'
      using errcode = 'P0002';
  end if;

  update public.subscription_orders set expires_at = v_now
    where landlord_uid = p_landlord_uid
      and id <> p_order_id
      and status = 'approved'
      and starts_at <= v_now
      and expires_at > v_now;

  update public.subscription_orders set
    starts_at = v_now,
    expires_at = v_now + interval '30 days'
  where id = p_order_id
  returning expires_at into v_next_starts_at;

  for v_queued in
    select id, starts_at, expires_at
      from public.subscription_orders
      where landlord_uid = p_landlord_uid
        and id <> p_order_id
        and status = 'approved'
        and starts_at > v_now
        and expires_at > v_now
      order by starts_at, created_at, id
  loop
    v_duration := v_queued.expires_at - v_queued.starts_at;
    if v_duration <= interval '0 seconds' then
      v_duration := interval '30 days';
    end if;
    update public.subscription_orders set
      starts_at = v_next_starts_at,
      expires_at = v_next_starts_at + v_duration
    where id = v_queued.id;
    v_next_starts_at := v_next_starts_at + v_duration;
  end loop;

  select * into v_order from public.subscription_orders where id = p_order_id;
  return to_jsonb(v_order);
end;
$$;

revoke all on function public.activate_scheduled_subscription_order(text, uuid)
  from public, anon, authenticated;
grant execute on function public.activate_scheduled_subscription_order(text, uuid)
  to service_role;
