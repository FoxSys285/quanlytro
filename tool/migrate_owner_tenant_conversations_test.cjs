const test = require('node:test');
const assert = require('node:assert/strict');
const { buildCanonical, canonicalId, planGroups } = require('./migrate_owner_tenant_conversations.cjs');

function conversation({ propertyId, ownerUid, tenantId, id, unread = 0, archived = false }) {
  return {
    path: `rental_records/${propertyId}:conversations:${encodeURIComponent(id)}`,
    data: {
      kind: 'conversations',
      propertyId,
      ownerUid,
      tenantIds: [tenantId],
      archived,
      data: {
        id,
        tenantId,
        tenantName: 'Tenant',
        landlordName: 'Owner',
        propertyName: propertyId,
        room: 'A1',
        unread,
        tenantUnread: unread,
        messages: [],
      },
    },
  };
}

function message({ propertyId, conversationId, id, text, createdAt, archived = false }) {
  return {
    path: `rental_records/${propertyId}:messages:${id}`,
    data: {
      kind: 'messages',
      propertyId,
      archived,
      data: {
        id,
        conversationKey: `${encodeURIComponent(propertyId)}:conversations:${encodeURIComponent(conversationId)}`,
        text,
        time: '09:00',
        createdAt,
        fromLandlord: false,
        index: 0,
        roomContext: {
          propertyId,
          roomId: 'A1',
          roomName: 'A1',
          propertyName: propertyId,
        },
      },
    },
  };
}

test('merge plan is scoped by owner UID and tenant ID, ignoring archived data', () => {
  const oldThread = conversation({ propertyId: 'property-z', ownerUid: 'owner-a', tenantId: 'tenant-a', id: 'room-thread', unread: 2 });
  const canonicalThread = conversation({ propertyId: 'property-a', ownerUid: 'owner-a', tenantId: 'tenant-a', id: canonicalId('owner-a', 'tenant-a'), unread: 1 });
  const otherOwner = conversation({ propertyId: 'property-b', ownerUid: 'owner-b', tenantId: 'tenant-a', id: 'other-owner-thread' });
  const otherTenant = conversation({ propertyId: 'property-c', ownerUid: 'owner-a', tenantId: 'tenant-b', id: 'other-tenant-thread' });
  const archived = conversation({ propertyId: 'property-d', ownerUid: 'owner-a', tenantId: 'tenant-a', id: 'archived-thread', archived: true });
  const messages = [
    message({ propertyId: 'property-z', conversationId: 'room-thread', id: 'message-1', text: 'same', createdAt: '2026-01-01T10:00:00Z' }),
    message({ propertyId: 'property-a', conversationId: canonicalId('owner-a', 'tenant-a'), id: 'message-1', text: 'same', createdAt: '2026-01-01T10:00:00Z' }),
    message({ propertyId: 'property-z', conversationId: 'room-thread', id: 'message-2', text: 'later', createdAt: '2026-01-01T11:00:00Z' }),
    message({ propertyId: 'property-d', conversationId: 'archived-thread', id: 'archived-message', text: 'ignored', createdAt: '2026-01-01T12:00:00Z', archived: true }),
  ];

  const plans = planGroups([oldThread, canonicalThread, otherOwner, otherTenant, archived], messages);
  const shared = plans.find((plan) => plan.ownerUid === 'owner-a' && plan.tenantId === 'tenant-a');
  assert.equal(plans.length, 3);
  assert.equal(shared.docs.length, 2);
  assert.equal(shared.uniqueMessageCount, 2);
  assert.equal(shared.duplicateMessageCount, 1);
  assert.equal(shared.relevantMessages.length, 3);

  const canonical = buildCanonical(shared);
  assert.equal(canonical.conversation.path, shared.targetPath);
  assert.equal(canonical.conversation.data.data.unread, 2);
  assert.equal(canonical.messages.length, 2);
  assert.deepEqual(canonical.messages.map((row) => row.data.data.text), ['same', 'later']);
  assert.equal(canonical.messages[0].data.data.conversationKey,
    `${encodeURIComponent(shared.targetPropertyId)}:conversations:${encodeURIComponent(shared.id)}`);
  assert.equal(canonical.conversation.data.ownerUid, 'owner-a');
  assert.deepEqual(canonical.conversation.data.tenantIds, ['tenant-a']);
});

test('a second plan ignores archived source rows after the first migration', () => {
  const source = conversation({ propertyId: 'property-z', ownerUid: 'owner-a', tenantId: 'tenant-a', id: 'legacy-thread' });
  const sourceMessage = message({ propertyId: 'property-z', conversationId: 'legacy-thread', id: 'message-1', text: 'Hello', createdAt: '2026-01-01T10:00:00Z' });
  const first = planGroups([source], [sourceMessage])[0];
  const canonical = buildCanonical(first);
  const second = planGroups(
    [
      { ...source, data: { ...source.data, archived: true } },
      canonical.conversation,
    ],
    [
      { ...sourceMessage, data: { ...sourceMessage.data, archived: true } },
      ...canonical.messages,
    ],
  );
  assert.equal(second.length, 1);
  assert.equal(second[0].docs.length, 1);
  assert.equal(second[0].relevantMessages.length, 1);
  assert.equal(second[0].uniqueMessageCount, 1);
});
