// Read-only by default. Review the generated plan and a Firestore export before
// using --apply in a controlled migration window.
const crypto = require('node:crypto');

const encodeComponent = (value) => encodeURIComponent(String(value));
const hash = (value) =>
  crypto.createHash('sha256').update(String(value)).digest('hex');
const canonicalId = (ownerUid, tenantId) =>
  `owner:${encodeComponent(ownerUid)}:${encodeComponent(tenantId)}`;
const recordPath = (propertyId, kind, id) =>
  `rental_records/${encodeComponent(propertyId)}:${kind}:${encodeComponent(id)}`;
const contextKey = (context) => `${context.propertyId}\u0000${context.roomId}`;

function timestampMillis(value) {
  if (value && typeof value.toMillis === 'function') return value.toMillis();
  const parsed = Date.parse(value ?? '');
  return Number.isFinite(parsed) ? parsed : 0;
}

function planGroups(conversations, messages) {
  const grouped = new Map();
  for (const doc of conversations) {
    const row = doc.data;
    if (row.archived === true) continue;
    const tenantId = row.tenantIds?.[0] ?? row.data?.tenantId;
    const ownerUid = row.ownerUid;
    if (!ownerUid || !tenantId) continue;
    const key = `${ownerUid}\u0000${tenantId}`;
    (grouped.get(key) ?? grouped.set(key, []).get(key)).push(doc);
  }

  const plans = [];
  for (const [key, docs] of grouped) {
    const ownerUid = docs[0].data.ownerUid;
    const tenantId = docs[0].data.tenantIds?.[0] ?? docs[0].data.data.tenantId;
    const id = canonicalId(ownerUid, tenantId);
    docs.sort((a, b) => {
      const aCanonical = a.data.data.id === id ? 0 : 1;
      const bCanonical = b.data.data.id === id ? 0 : 1;
      return aCanonical - bCanonical ||
        a.data.propertyId.localeCompare(b.data.propertyId);
    });
    const targetPropertyId = docs[0].data.propertyId;
    const targetPath = recordPath(targetPropertyId, 'conversations', id);
    const conversationKeys = new Set(
      docs.map((doc) => `${encodeComponent(doc.data.propertyId)}:conversations:${encodeComponent(doc.data.data.id)}`),
    );
    const relevantMessages = messages.filter((message) =>
      message.data.archived !== true &&
      conversationKeys.has(message.data.data?.conversationKey),
    );
    const messageIds = new Set();
    let duplicateMessages = 0;
    for (const message of relevantMessages) {
      const data = message.data.data;
      const messageId = data.id ?? `legacy-${hash(`${data.fromLandlord}:${data.createdAt ?? data.time}:${data.text}`)}`;
      if (messageIds.has(messageId)) duplicateMessages++;
      messageIds.add(messageId);
    }
    plans.push({
      key,
      ownerUid,
      tenantId,
      id,
      targetPropertyId,
      targetPath,
      sourcePaths: docs.map((doc) => doc.path),
      messagePaths: relevantMessages.map((doc) => doc.path),
      uniqueMessageCount: messageIds.size,
      duplicateMessageCount: duplicateMessages,
      docs,
      relevantMessages,
    });
  }
  return plans;
}

function buildCanonical(plan) {
  const sources = plan.docs;
  const primary = sources[0].data.data;
  const messageMap = new Map();
  for (const source of sources) {
    for (const context of source.data.data.roomContexts ?? []) {
      // Include persisted room context in the merged thread metadata below.
      if (context && typeof context.propertyId === 'string') {
        messageMap.set(`context:${contextKey(context)}`, { roomContext: context });
      }
    }
    const lastContext = source.data.data.lastRoomContext;
    if (lastContext && typeof lastContext.propertyId === 'string') {
      messageMap.set(`context:${contextKey(lastContext)}`, { roomContext: lastContext });
    }
  }
  const uniqueMessages = new Map();
  for (const row of plan.relevantMessages) {
    const message = { ...row.data.data };
    const messageId = message.id ?? `legacy-${hash(`${message.fromLandlord}:${message.createdAt ?? message.time}:${message.text}`)}`;
    if (uniqueMessages.has(messageId)) continue;
    message.id = messageId;
    uniqueMessages.set(messageId, message);
  }
  const orderedMessages = [...uniqueMessages.values()].sort((a, b) =>
    timestampMillis(a.createdAt) - timestampMillis(b.createdAt) ||
    (a.index ?? 0) - (b.index ?? 0) || a.id.localeCompare(b.id),
  );
  const contexts = new Map(messageMap);
  for (const message of orderedMessages) {
    const context = message.roomContext;
    if (context && typeof context.propertyId === 'string') {
      contexts.set(`context:${contextKey(context)}`, { roomContext: context });
    }
  }
  const roomContexts = [...contexts.values()].map((entry) => entry.roomContext);
  const lastRoomContext = orderedMessages
    .map((message) => message.roomContext)
    .filter(Boolean)
    .at(-1) ?? roomContexts.at(-1) ?? primary.lastRoomContext ?? null;
  const data = {
    ...primary,
    id: plan.id,
    ownerUid: plan.ownerUid,
    tenantId: plan.tenantId,
    propertyId: plan.targetPropertyId,
    room: lastRoomContext?.roomName ?? primary.room,
    propertyName: lastRoomContext?.propertyName ?? primary.propertyName,
    unread: Math.max(...sources.map((source) => source.data.data.unread ?? 0)),
    tenantUnread: Math.max(...sources.map((source) => source.data.data.tenantUnread ?? 0)),
    roomContexts,
    lastRoomContext,
    messages: [],
  };
  const envelope = {
    ...sources[0].data,
    propertyId: plan.targetPropertyId,
    ownerUid: plan.ownerUid,
    tenantIds: [plan.tenantId],
    archived: false,
    data,
  };
  const conversationKey = `${encodeComponent(plan.targetPropertyId)}:conversations:${encodeComponent(plan.id)}`;
  const messageRows = orderedMessages.map((message, index) => {
    const data = {
      ...message,
      conversationId: plan.id,
      conversationKey,
      index,
    };
    const id = `${plan.id}:${message.id}`;
    return {
      path: recordPath(plan.targetPropertyId, 'messages', id),
      data: {
        kind: 'messages',
        propertyId: plan.targetPropertyId,
        ownerUid: plan.ownerUid,
        tenantIds: [plan.tenantId],
        archived: false,
        data,
      },
    };
  });
  return {
    conversation: { path: plan.targetPath, data: envelope },
    messages: messageRows,
  };
}

async function commitInChunks(db, writes) {
  for (let offset = 0; offset < writes.length; offset += 400) {
    const batch = db.batch();
    for (const write of writes.slice(offset, offset + 400)) {
      if (write.merge) batch.set(db.doc(write.path), write.data, { merge: true });
      else batch.set(db.doc(write.path), write.data);
    }
    await batch.commit();
  }
}

async function main() {
  const apply = process.argv.includes('--apply');
  const projectId = process.env.FIREBASE_PROJECT_ID;
  if (!projectId) throw new Error('Set FIREBASE_PROJECT_ID for the preview or migration.');
  const admin = require('firebase-admin');
  if (!admin.apps.length) {
    admin.initializeApp({ projectId, credential: admin.credential.applicationDefault() });
  }
  const db = admin.firestore();
  const [conversationSnapshot, messageSnapshot] = await Promise.all([
    db.collection('rental_records').where('kind', '==', 'conversations').get(),
    db.collection('rental_records').where('kind', '==', 'messages').get(),
  ]);
  const conversations = conversationSnapshot.docs.map((doc) => ({ path: doc.ref.path, data: doc.data() }));
  const messages = messageSnapshot.docs.map((doc) => ({ path: doc.ref.path, data: doc.data() }));
  const plans = planGroups(conversations, messages);
  const preview = plans.map(({ sourcePaths, messagePaths, uniqueMessageCount, duplicateMessageCount }, index) => ({
    group: index + 1,
    sourceConversationCount: sourcePaths.length,
    sourceMessageCount: messagePaths.length,
    uniqueMessageCount,
    duplicateMessageCount,
  }));
  process.stdout.write(`${JSON.stringify({ mode: apply ? 'apply' : 'preview', groups: preview.length, plan: preview }, null, 2)}\n`);
  if (!apply) return;

  const backupWrites = [];
  const migrationWrites = [];
  for (const plan of plans) {
    const canonical = buildCanonical(plan);
    const backupId = hash(plan.key).slice(0, 32);
    const allSourceDocs = [...plan.docs, ...plan.relevantMessages];
    for (const source of allSourceDocs) {
      const backupPath = `rental_migration_backups/${backupId}/documents/${hash(source.path).slice(0, 32)}`;
      backupWrites.push({
        path: backupPath,
        data: { sourcePath: source.path, envelope: source.data, copiedAt: admin.firestore.FieldValue.serverTimestamp() },
      });
    }
    backupWrites.push({
      path: `rental_migration_backups/${backupId}`,
      data: {
        type: 'owner-tenant-conversation-merge',
        ownerUid: plan.ownerUid,
        tenantId: plan.tenantId,
        targetPath: plan.targetPath,
        sourcePaths: plan.docs.map((doc) => doc.path),
        messagePaths: plan.relevantMessages.map((doc) => doc.path),
        copiedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    });
    migrationWrites.push({ path: canonical.conversation.path, data: canonical.conversation.data, merge: true });
    migrationWrites.push(...canonical.messages.map((row) => ({ ...row, merge: true })));
    const canonicalSourcePath = plan.docs.find((doc) => doc.data.data.id === plan.id)?.path;
    for (const source of plan.docs) {
      if (source.path !== canonicalSourcePath && source.path !== plan.targetPath) {
        migrationWrites.push({ path: source.path, data: { ...source.data, archived: true }, merge: true });
      }
    }
    for (const source of plan.relevantMessages) {
      const sourceConversationKey = source.data.data?.conversationKey;
      if (source.data.propertyId !== plan.targetPropertyId ||
          typeof sourceConversationKey !== 'string' ||
          !sourceConversationKey.endsWith(`:conversations:${encodeComponent(plan.id)}`)) {
        migrationWrites.push({ path: source.path, data: { ...source.data, archived: true }, merge: true });
      }
    }
  }
  await commitInChunks(db, backupWrites);
  await commitInChunks(db, migrationWrites);
  process.stdout.write(`Backed up ${backupWrites.length} documents and applied ${migrationWrites.length} writes.\n`);
}

if (require.main === module) {
  main().catch((error) => {
    process.stderr.write(`${error.stack ?? error}\n`);
    process.exitCode = 1;
  });
}

module.exports = { buildCanonical, canonicalId, planGroups, recordPath };
