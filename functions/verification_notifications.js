// Derive events from persisted reviews/submissions, not client success toasts.
function verificationNotification(before, after) {
  if (!after || after.archived) return null;
  const item = after.data || {};
  const old = before?.data || {};
  if (after.kind === 'verificationReview' && String(item.note || '').trim() &&
      (old.note !== item.note || old.requestedAt !== item.requestedAt)) {
    return {
      audience: 'owner',
      title: 'Cần bổ sung hồ sơ xác minh',
      body: `Quản trị viên yêu cầu: ${item.note}`,
      type: 'verification_supplement',
      route: 'verification',
    };
  }
  if (after.kind === 'verification' && item.submittedAt && old.submittedAt !== item.submittedAt) {
    return {
      audience: 'admins',
      title: old.submittedAt ? 'Chủ trọ đã gửi lại hồ sơ xác minh' : 'Có hồ sơ xác minh nhà trọ mới',
      body: 'Hồ sơ đã được gửi. Vui lòng mở mục Xác minh nhà trọ để kiểm tra.',
      type: 'verification_submitted',
      route: 'property_verification',
    };
  }
  return null;
}

module.exports = { verificationNotification };
