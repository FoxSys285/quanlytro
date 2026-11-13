const fs = require('node:fs');
const assert = require('node:assert/strict');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('../.dart_tool/firebase_tools/node_modules/@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, collection, query, where, getDocs, writeBatch } = require('../.dart_tool/firebase_tools/node_modules/firebase/firestore');

(async () => {
  const env = await initializeTestEnvironment({projectId: 'demo-quanlytro', firestore: {host: '127.0.0.1', port: 8080, rules: fs.readFileSync('firestore.rules', 'utf8')}});
  const row = (kind, data, owner = 'owner-a', tenant = 'tenant-a') => ({kind, ownerUid: owner, propertyId: 'may', tenantIds: [tenant], archived: false, data});
  try {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async ctx => {
      const db = ctx.firestore();
      for (const [uid, role, tenantId] of [['owner-a','landlord',null], ['owner-b','landlord',null], ['tenant-a','tenant','tenant-a'], ['tenant-b','tenant','tenant-b'], ['admin-a','admin',null], ['disabled-a','tenant','tenant-a']]) {
        await setDoc(doc(db, 'users', uid), {role, tenantId, disabled: uid === 'disabled-a'});
      }
      await setDoc(doc(db, 'tenant_codes/MEMBER01'), {createdAt: new Date()});
      await setDoc(doc(db, 'rental_properties/may'), {ownerUid: 'owner-a', data: {property: {name:'May'}}});
      await setDoc(doc(db, 'rental_records/may:leases:HD-1'), row('leases', {id:'HD-1', tenantId:'tenant-a', status:'active'}));
      await setDoc(doc(db, 'rental_records/may:invoices:INV-1'), row('invoices', {id:'INV-1', leaseId:'HD-1', paidAmount:0, cancelled:false}));
      await setDoc(doc(db, 'rental_records/chat-a'), row('conversations', {id:'chat-a', messages:[], unread:0, tenantUnread:1}));
      await setDoc(doc(db, 'public_rooms/room-a'), {ownerUid:'owner-a', propertyId:'may', published:false, price:100});
      await setDoc(doc(db, 'rental_records/notices-a'), row('tenantAnnouncements', {recipients:{'notice-1':['tenant-a']},readByTenant:{'tenant-a':[]}}));
      await setDoc(doc(db, 'rental_records/incident-a'), row('incidents', {status:'resolved'}));
      await setDoc(doc(db, 'app_documents/portfolio'), {payload:'private legacy'});
    });
    const guest = env.unauthenticatedContext().firestore();
    const tenant = env.authenticatedContext('tenant-a').firestore();
    const other = env.authenticatedContext('tenant-b').firestore();
    const owner = env.authenticatedContext('owner-a').firestore();
    const foreignOwner = env.authenticatedContext('owner-b').firestore();
    const admin = env.authenticatedContext('admin-a').firestore();
    const disabled = env.authenticatedContext('disabled-a').firestore();
    await assertSucceeds(getDoc(doc(guest, 'rental_properties/may')));
    await assertFails(getDoc(doc(guest, 'rental_records/may:leases:HD-1')));
    await assertFails(getDoc(doc(tenant, 'app_documents/portfolio')));
    await assertSucceeds(getDoc(doc(tenant, 'rental_records/may:leases:HD-1')));
    await assertFails(getDoc(doc(other, 'rental_records/may:leases:HD-1')));
    await assertFails(getDoc(doc(disabled, 'rental_records/may:leases:HD-1')));
    await assertFails(setDoc(doc(tenant, 'users/tenant-a'), {role:'admin', disabled:false}));
    await assertFails(updateDoc(doc(tenant, 'users/tenant-b'), {disabled:true}));
    await assertFails(updateDoc(doc(admin, 'users/admin-a'), {disabled:true}));
    await assertFails(updateDoc(doc(admin, 'users/tenant-b'), {role:'admin'}));
    await assertSucceeds(updateDoc(doc(admin, 'users/tenant-b'), {disabled:true}));
    await assertSucceeds(updateDoc(doc(admin, 'users/tenant-b'), {disabled:false}));
    await assertSucceeds(getDocs(query(collection(owner, 'rental_records'), where('ownerUid', '==', 'owner-a'))));
    await assertSucceeds(getDocs(query(collection(tenant, 'rental_records'), where('tenantIds', 'array-contains', 'tenant-a'))));
    await assertFails(getDocs(collection(tenant, 'rental_records')));
    await assertFails(updateDoc(doc(foreignOwner, 'rental_records/may:invoices:INV-1'), {'data.paidAmount':100000}));
    await assertFails(updateDoc(doc(tenant, 'rental_records/may:invoices:INV-1'), {'data.paidAmount':100000}));
    const payment = row('payments', {invoiceId:'INV-1', status:'pending', reportedAmount:100000, approvedAmount:null, reviewedAt:null});
    await assertSucceeds(setDoc(doc(tenant, 'rental_records/payment-a'), payment));
    await assertFails(setDoc(doc(other, 'rental_records/payment-b'), payment));
    await assertFails(setDoc(doc(tenant, 'rental_records/payment-c'), {...payment, data:{...payment.data,status:'approved',approvedAmount:100000}}));
    await assertFails(updateDoc(doc(tenant, 'rental_records/payment-a'), {'data.status':'approved'}));
    await assertSucceeds(updateDoc(doc(owner, 'rental_records/payment-a'), {'data.status':'approved','data.approvedAmount':100000}));
    await assertSucceeds(setDoc(doc(tenant, 'rental_records/member-a'), row('members', {leaseId:'HD-1',tenantId:'MEMBER01',requestedBy:'tenant-a',status:'pending',isRepresentative:false})));
    await assertFails(setDoc(doc(tenant, 'rental_records/member-b'), row('members', {leaseId:'NOT-MINE',tenantId:'MEMBER01',requestedBy:'tenant-a',status:'pending',isRepresentative:false})));
    await assertSucceeds(setDoc(doc(tenant, 'rental_records/message-a'), row('messages', {conversationKey:'chat-a', conversationId:'chat-a', index:0,text:'Hello',time:'09:00',fromLandlord:false})));
    await assertFails(setDoc(doc(tenant, 'rental_records/message-forged'), row('messages', {conversationKey:'chat-a',index:1,text:'Fake owner',fromLandlord:true})));
    await assertFails(setDoc(doc(tenant, 'rental_records/message-cross-chat'), row('messages', {conversationKey:'chat-a',conversationId:'victim-chat',index:1,text:'Wrong recipient',fromLandlord:false})));
    await assertFails(updateDoc(doc(tenant, 'rental_records/message-a'), {'data.text':'Rewrite history'}));
    await assertSucceeds(updateDoc(doc(tenant, 'rental_records/chat-a'), {'data.tenantUnread':0,'data.unread':1}));
    await assertFails(updateDoc(doc(tenant, 'rental_records/chat-a'), {'data.unread':0}));
    await assertSucceeds(setDoc(doc(owner, 'rental_records/message-owner'), row('messages', {conversationKey:'chat-a', conversationId:'chat-a',index:1,text:'Reply',time:'09:01',fromLandlord:true})));
    await assertFails(setDoc(doc(owner, 'rental_records/message-owner-spoof'), row('messages', {conversationKey:'chat-a',conversationId:'chat-a',index:2,text:'Spoof',fromLandlord:false})));
    await assertSucceeds(updateDoc(doc(owner, 'public_rooms/room-a'), {price:200}));
    await assertFails(updateDoc(doc(owner, 'public_rooms/room-a'), {published:true}));
    await assertSucceeds(updateDoc(doc(admin, 'public_rooms/room-a'), {published:true}));
    await assertSucceeds(updateDoc(doc(admin, 'rental_properties/may'), {published:false}));
    await assertFails(updateDoc(doc(owner, 'rental_properties/may'), {published:true}));
    await assertFails(setDoc(doc(owner, 'public_rooms/hidden-new-room'), {ownerUid:'owner-a',propertyId:'may',published:true}));
    await assertSucceeds(setDoc(doc(owner, 'public_rooms/hidden-unpublished-room'), {ownerUid:'owner-a',propertyId:'may',published:false}));
    const newId = 'property-owner-a-1';
    const newData = {
      ownerUid: 'owner-a', published: true, verified: false, verificationProof: '',
      data: {schemaVersion: 2, property: {id: newId, name: 'New house'}, rooms: [], roomTypes: [], services: []},
    };
    await assertFails(setDoc(doc(owner, 'rental_properties/forged-owner'), {...newData, ownerUid: 'owner-b'}));
    await assertFails(setDoc(doc(owner, 'rental_properties/forged-id'), {...newData, data: {...newData.data, property: {id: 'different'}}}));
    await assertFails(setDoc(doc(owner, 'rental_properties/forged-verified'), {...newData, verified: true}));
    await assertFails(setDoc(doc(foreignOwner, 'rental_properties/foreign-create'), newData));
    const newProperty = writeBatch(owner);
    newProperty.set(doc(owner, `rental_properties/${newId}`), newData);
    for (let i = 1; i <= 18; i++) {
      newProperty.set(doc(owner, `public_rooms/new-house-room-${i}`), {ownerUid:'owner-a',propertyId:newId,published:true});
    }
    await assertSucceeds(newProperty.commit());
    await assertSucceeds(updateDoc(doc(tenant, 'rental_records/notices-a'), {'data.readByTenant':{'tenant-a':['notice-1']}}));
    await assertFails(updateDoc(doc(tenant, 'rental_records/notices-a'), {'data.readByTenant':{'tenant-b':['notice-1']}}));
    await assertFails(updateDoc(doc(tenant, 'rental_records/notices-a'), {'data.readByTenant':{'tenant-a':['invented-notice']}}));
    await assertSucceeds(updateDoc(doc(tenant, 'rental_records/incident-a'), {'data.status':'newly'}));
    await assertSucceeds(setDoc(doc(admin, 'public_settings/viewings'), {acceptingViewings:false}));
    await assertFails(setDoc(doc(tenant, 'rental_records/viewing-blocked'), row('viewings', {tenantId:'tenant-a',status:'pending'})));
    await assertSucceeds(setDoc(doc(admin, 'public_settings/viewings'), {acceptingViewings:true}));
    await assertSucceeds(setDoc(doc(tenant, 'rental_records/viewing-open'), row('viewings', {tenantId:'tenant-a',status:'pending'})));
    await assertSucceeds(updateDoc(doc(owner, 'rental_records/may:invoices:INV-1'), {'data.cancelled':true}));
    await assertFails(setDoc(doc(tenant, 'rental_records/payment-cancelled-invoice'), payment));
    await assertSucceeds(updateDoc(doc(owner, 'rental_records/may:leases:HD-1'), {'data.status':'terminated'}));
    await assertFails(setDoc(doc(tenant, 'rental_records/member-ended-lease'), row('members', {leaseId:'HD-1',tenantId:'MEMBER01',requestedBy:'tenant-a',status:'pending',isRepresentative:false})));
    await assertSucceeds(getDoc(doc(admin, 'rental_records/may:leases:HD-1')));
    assert.equal((await getDoc(doc(owner, 'rental_records/payment-a'))).data().data.status, 'approved');
    console.log('RULES_CHECKS_PASSED: public catalog, scoped queries, role escalation, cross-user isolation, payment approval and immutable messages');
  } finally { await env.cleanup(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
