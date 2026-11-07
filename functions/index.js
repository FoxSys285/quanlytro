const crypto = require('node:crypto');
const admin = require('firebase-admin');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
const channelId = 'tro_premium_updates';

const hash = (value) => crypto.createHash('sha256').update(value).digest('hex');
const dataPayload = (type, propertyId, entityId, route) => ({
  type,
  propertyId: String(propertyId || ''),
  entityId: String(entityId || ''),
  route,
});

async function sendToUser(uid, eventKey, title, body, data = {}) {
  if (!uid || !title || !body) return;
  const marker = db.collection('notification_deliveries').doc(hash(`${eventKey}:${uid}`));
  if ((await marker.get()).exists) return;
  const devices = await db.collection('users').doc(uid).collection('devices')
    .where('enabled', '==', true).get();
  const targets = devices.docs.filter((doc) => doc.get('token'));
  if (!targets.length) return;
  const result = await messaging.sendEachForMulticast({
    tokens: targets.map((doc) => doc.get('token')),
    notification: { title, body },
    data: Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value ?? '')])),
    android: { priority: 'high', notification: { channelId, sound: 'default' } },
    apns: { payload: { aps: { sound: 'default' } } },
  });
  const cleanup = [];
  result.responses.forEach((response, index) => {
    if (!response.success && [
      'messaging/registration-token-not-registered',
      'messaging/invalid-registration-token',
    ].includes(response.error?.code)) cleanup.push(targets[index].ref.delete());
  });
  await Promise.all(cleanup);
  if (result.successCount) {
    await marker.set({ uid, eventKey, sentAt: admin.firestore.FieldValue.serverTimestamp() });
  }
}

async function sendToTenants(tenantIds, eventKey, title, body, data) {
  const ids = [...new Set((tenantIds || []).filter(Boolean))];
  for (let offset = 0; offset < ids.length; offset += 30) {
    const users = await db.collection('users').where('tenantId', 'in', ids.slice(offset, offset + 30)).get();
    await Promise.all(users.docs
      .filter((user) => user.get('role') === 'tenant' && user.get('disabled') !== true)
      .map((user) => sendToUser(user.id, eventKey, title, body, data)));
  }
}

function read(snapshot) {
  return snapshot?.exists ? snapshot.data() : null;
}

exports.onRentalRecordWritten = onDocumentWritten('rental_records/{recordId}', async (event) => {
  const before = read(event.data?.before);
  const after = read(event.data?.after);
  if (!after || after.archived) return;
  const item = after.data || {};
  const old = before?.data || {};
  const ownerUid = after.ownerUid;
  const tenants = after.tenantIds || [];
  const propertyId = after.propertyId || '';
  const id = item.id || event.params.recordId;
  const eventKey = event.id;
  const info = (type, route) => dataPayload(type, propertyId, id, route);

  if (after.kind === 'messages' && !before) {
    if (item.fromLandlord) {
      await sendToTenants(tenants, eventKey, 'Tin nhắn mới từ chủ trọ', item.text, info('message', 'messages'));
    } else {
      await sendToUser(ownerUid, eventKey, 'Tin nhắn mới từ người thuê', item.text, info('message', 'messages'));
    }
    return;
  }
  if (after.kind === 'tenantAnnouncements') {
    if (!before) return;
    const oldIds = new Set((old.sent || []).map((notice) => notice.id));
    for (const notice of item.sent || []) {
      if (oldIds.has(notice.id) || !String(notice.id).startsWith('announcement-')) continue;
      await sendToTenants(tenants, `${eventKey}:${notice.id}`, notice.title, notice.content, info('landlord_announcement', 'announcements'));
    }
    return;
  }
  if (after.kind === 'invoices' && !before) {
    await sendToTenants(tenants, eventKey, 'Chủ trọ đã lập phiếu thu', `Hóa đơn ${item.id} đã được tạo. Vui lòng kiểm tra số tiền và hạn thanh toán.`, info('invoice_created', 'invoices'));
    return;
  }
  if (after.kind === 'payments') {
    if (!before && item.status === 'pending') {
      await sendToUser(ownerUid, eventKey, 'Người thuê gửi thanh toán', `Phòng ${item.room}: ${item.reportedAmount} đ. Vui lòng kiểm tra và duyệt.`, info('payment_pending', 'payments'));
    } else if (before && old.status !== item.status && ['approved', 'rejected'].includes(item.status)) {
      const title = item.status === 'approved' ? 'Thanh toán đã được duyệt' : 'Thanh toán bị từ chối';
      const body = item.status === 'approved'
        ? `Khoản ${item.id} cho hóa đơn ${item.invoiceId} đã được xác nhận.`
        : `Khoản ${item.id} chưa được duyệt. Lý do: ${item.rejectionReason || 'Chủ trọ chưa ghi lý do.'}`;
      await sendToTenants(tenants, eventKey, title, body, info('payment_reviewed', 'invoices'));
    }
    return;
  }
  if (after.kind === 'incidents') {
    if (!before) {
      await sendToUser(ownerUid, eventKey, 'Người thuê báo sự cố', `Phòng ${item.room}: ${item.title}`, info('incident_reported', 'incidents'));
    } else if (old.status !== item.status) {
      await sendToTenants(tenants, eventKey, 'Trạng thái sự cố được cập nhật', `${item.title}: ${item.status}`, info('incident_status', 'incidents'));
    }
    return;
  }
  if (after.kind === 'viewings') {
    if (!before && item.status === 'pending') {
      await sendToUser(ownerUid, eventKey, 'Có yêu cầu xem phòng mới', `${item.customerName} · ${item.roomName}`, info('viewing_requested', 'viewings'));
    } else if (before && old.status !== item.status && ['confirmed', 'cancelled'].includes(item.status)) {
      const title = item.status === 'confirmed' ? 'Lịch xem phòng đã được duyệt' : 'Lịch xem phòng đã bị hủy';
      await sendToTenants(tenants, eventKey, title, `${item.roomName} · ${item.startsAt}`, info('viewing_reviewed', 'viewings'));
    }
    return;
  }
  if (after.kind === 'members') {
    if (!before && item.status === 'pending') {
      await sendToUser(ownerUid, eventKey, 'Yêu cầu thêm thành viên', `${item.name} · Mã người thuê ${item.tenantId}`, info('member_requested', 'members'));
    } else if (before && old.status !== item.status && ['active', 'rejected'].includes(item.status)) {
      const title = item.status === 'active' ? 'Yêu cầu thêm thành viên đã duyệt' : 'Yêu cầu thêm thành viên bị từ chối';
      const body = item.status === 'active'
        ? 'Bạn đã được thêm vào phòng. Hãy bổ sung ảnh CCCD hai mặt và ảnh chân dung.'
        : `Lý do: ${item.rejectionReason || 'Chủ trọ chưa ghi lý do.'}`;
      await sendToTenants([item.tenantId, item.requestedBy], eventKey, title, body, info('member_reviewed', 'members'));
    } else if (before && old.leaveRequestedAt !== item.leaveRequestedAt && item.leaveRequestedAt) {
      const others = tenants.filter((tenantId) => tenantId !== item.tenantId);
      await Promise.all([
        sendToUser(ownerUid, eventKey, 'Thành viên xin rời phòng', `${item.name} · ${item.leaveReason || ''}`, info('member_leave', 'members')),
        sendToTenants(others, eventKey, 'Thành viên xin rời phòng', `${item.name} · dự kiến ${item.leaveEffectiveAt || ''}`, info('member_leave', 'members')),
      ]);
    } else if (before && old.leaveAcknowledgedAt !== item.leaveAcknowledgedAt && item.leaveAcknowledgedAt) {
      await sendToTenants([item.tenantId], eventKey, 'Chủ trọ đã nhận yêu cầu rời phòng', `${item.name} · ${item.leaveEffectiveAt || ''}`, info('member_leave', 'members'));
    } else if (before && old.status !== item.status && item.status === 'left') {
      await Promise.all([
        sendToUser(ownerUid, eventKey, 'Thành viên đã rời phòng', item.name, info('member_leave', 'members')),
        sendToTenants(tenants, eventKey, 'Thành viên đã rời phòng', item.name, info('member_leave', 'members')),
      ]);
    }
    return;
  }
  if (after.kind === 'leases') {
    if (before && old.status !== item.status && item.status === 'terminated') {
      await sendToTenants(tenants, eventKey, 'Hợp đồng đã chấm dứt', item.terminationReason || 'Chủ trọ đã cập nhật trạng thái hợp đồng.', info('lease_terminated', 'lease'));
    } else if (before && old.terminationRequestStatus !== item.terminationRequestStatus && item.terminationRequestStatus === 'pending') {
      await sendToUser(ownerUid, eventKey, 'Người thuê đề nghị kết thúc hợp đồng', `Phòng ${item.room} · ${item.terminationRequestReason || ''}`, info('lease_termination_request', 'leases'));
    } else if (before && old.terminationRequestStatus !== item.terminationRequestStatus && item.terminationRequestStatus === 'rejected') {
      await sendToTenants(tenants, eventKey, 'Yêu cầu kết thúc hợp đồng bị từ chối', item.terminationRejectionReason || 'Chủ trọ chưa ghi lý do.', info('lease_termination_review', 'lease'));
    } else if (before && old.renewalStatus !== item.renewalStatus && item.renewalStatus === 'pending') {
      await sendToUser(ownerUid, eventKey, 'Yêu cầu gia hạn hợp đồng', `Phòng ${item.room} · đến ${item.renewalProposedEndDate || ''}`, info('lease_renewal', 'leases'));
    } else if (before && old.renewalStatus !== item.renewalStatus && ['approved', 'rejected'].includes(item.renewalStatus)) {
      const title = item.renewalStatus === 'approved' ? 'Yêu cầu gia hạn đã được duyệt' : 'Yêu cầu gia hạn bị từ chối';
      await sendToTenants(tenants, eventKey, title, item.renewalRejectionReason || `Hợp đồng phòng ${item.room} được cập nhật.`, info('lease_renewal', 'lease'));
    }
  }
});

exports.onPropertyVerificationWritten = onDocumentWritten('rental_properties/{propertyId}', async (event) => {
  const before = read(event.data?.before);
  const after = read(event.data?.after);
  if (!before || !after || after.verified !== true || before.verified === true) return;
  await sendToUser(after.ownerUid, event.id, 'Nhà trọ đã được xác minh',
    'Quản trị viên đã duyệt hồ sơ xác minh nhà trọ.',
    dataPayload('property_verified', event.params.propertyId, event.params.propertyId, 'properties'));
});

function localDateKey(date = new Date()) {
  const values = Object.fromEntries(new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Ho_Chi_Minh', year: 'numeric', month: '2-digit', day: '2-digit',
  }).formatToParts(date).map((part) => [part.type, part.value]));
  return `${values.year}-${values.month}-${values.day}`;
}
const daysBetween = (from, to) => Math.round((Date.parse(`${to}T00:00:00Z`) - Date.parse(`${from}T00:00:00Z`)) / 86400000);

exports.dailyRentalReminders = onSchedule({ schedule: '0 9 * * *', timeZone: 'Asia/Ho_Chi_Minh' }, async () => {
  const today = localDateKey();
  const [invoices, leases] = await Promise.all([
    db.collection('rental_records').where('kind', '==', 'invoices').get(),
    db.collection('rental_records').where('kind', '==', 'leases').get(),
  ]);
  for (const doc of invoices.docs) {
    const record = doc.data();
    const invoice = record.data || {};
    const total = (invoice.charges || []).reduce((sum, charge) => sum + (charge.amount || 0), 0);
    const remaining = total - (invoice.paidAmount || 0);
    if (invoice.cancelled || remaining <= 0 || !invoice.dueDate || invoice.dueDate >= today) continue;
    const key = `invoice-overdue:${record.propertyId}:${invoice.id}:${invoice.dueDate}`;
    const info = dataPayload('invoice_overdue', record.propertyId, invoice.id, 'invoices');
    await Promise.all([
      sendToUser(record.ownerUid, key, 'Hóa đơn đã quá hạn', `Phòng ${invoice.room} còn ${remaining} đ chưa thanh toán.`, info),
      sendToTenants(record.tenantIds, key, 'Hóa đơn đã quá hạn', `Hóa đơn ${invoice.id} còn ${remaining} đ chưa thanh toán.`, info),
    ]);
  }
  for (const doc of leases.docs) {
    const record = doc.data();
    const lease = record.data || {};
    if (lease.status !== 'active' || !lease.endDate) continue;
    const endDate = lease.endDate.slice(0, 10);
    const days = daysBetween(today, endDate);
    const info = dataPayload(days < 0 ? 'lease_overdue' : 'lease_expiring', record.propertyId, lease.id, 'lease');
    if (days === 30) {
      const key = `lease-expiring-30:${record.propertyId}:${lease.id}:${endDate}`;
      await Promise.all([
        sendToUser(record.ownerUid, key, 'Hợp đồng còn một tháng', `Phòng ${lease.room} · hết hạn ${endDate}.`, info),
        sendToTenants(record.tenantIds, key, 'Hợp đồng còn một tháng', `Hợp đồng phòng ${lease.room} sắp hết hạn. Bạn có thể gửi yêu cầu gia hạn trong ứng dụng.`, info),
      ]);
    } else if (days < 0) {
      const key = `lease-overdue:${record.propertyId}:${lease.id}:${endDate}`;
      await Promise.all([
        sendToUser(record.ownerUid, key, 'Hợp đồng đã quá hạn', `Hợp đồng phòng ${lease.room} đã hết hiệu lực.`, info),
        sendToTenants(record.tenantIds, key, 'Hợp đồng đã quá hạn', `Hợp đồng thuê phòng ${lease.room} đã hết hạn.`, info),
      ]);
    }
  }
});
