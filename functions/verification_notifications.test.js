const { test } = require('node:test');
const assert = require('node:assert/strict');
const { verificationNotification } = require('./verification_notifications');
const review = (note, requestedAt = 'r1') => ({ kind: 'verificationReview', data: { note, requestedAt } });
const submission = (submittedAt) => ({ kind: 'verification', data: { submittedAt } });

test('Supplement requests notify the owner, including repeated requests with the same reason', () => {
  assert.equal(verificationNotification(null, review('Bổ sung ảnh CCCD')).audience, 'owner');
  assert.equal(verificationNotification(review('CCCD'), review('CCCD')), null);
  assert.equal(verificationNotification(review('CCCD'), review('CCCD', 'r2')).type, 'verification_supplement');
  assert.equal(verificationNotification(review('CCCD'), review('')), null);
  assert.equal(verificationNotification(null, { ...review('CCCD'), archived: true }), null);
});

test('Only a new submission revision notifies admins', () => {
  assert.equal(verificationNotification(null, submission('s1')).audience, 'admins');
  assert.match(verificationNotification(submission('s1'), submission('s2')).title, /gửi lại/);
  assert.equal(verificationNotification(submission('s1'), submission('s1')), null);
  assert.equal(verificationNotification(null, submission(null)), null);
  assert.equal(verificationNotification(submission('s1'), null), null);
});
