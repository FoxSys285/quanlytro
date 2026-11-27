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
      await setDoc(doc(db, 'rental_records/may:leases:HD-1'), row('leases', {id:'HD-1', tenantId:'tenant-a', status:'active', cashPaymentEnabled:true, bankTransferEnabled:true}));
      await setDoc(doc(db, 'rental_records/may:leases:HD-2'), row('leases', {id:'HD-2', tenantId:'tenant-a', status:'active', cashPaymentEnabled:true, bankTransferEnabled:true}));
      await setDoc(doc(db, 'rental_records/may:members:member-1'), row('members', {id:'member-1', leaseId:'HD-1', tenantId:'tenant-a', status:'active', isRepresentative:false, leaveReason:'', leaveRequestedAt:null, leaveEffectiveAt:null, leaveAcknowledgedAt:null}));
      await setDoc(doc(db, 'rental_records/may:invoices:INV-1'), row('invoices', {id:'INV-1', leaseId:'HD-1', paidAmount:0, cancelled:false, pendingPaymentId:null, lastApprovedPaymentId:null}));
      await setDoc(doc(db, 'rental_records/may:invoices:INV-TRANSFER'), row('invoices', {id:'INV-TRANSFER', leaseId:'HD-1', paidAmount:0, cancelled:false, pendingPaymentId:null, lastApprovedPaymentId:null}));
      await setDoc(doc(db, 'rental_records/may:viewings:viewing-1'), row('viewings', {id:'viewing-1', tenantId:'tenant-a', status:'pending', startsAt:'2026-11-28T10:00:00.000Z'}));
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
    await assertFails(updateDoc(doc(tenant, 'rental_records/may:viewings:viewing-1'), {'data.status':'confirmed'}));
    await assertSucceeds(updateDoc(doc(owner, 'rental_records/may:viewings:viewing-1'), {'data.status':'confirmed'}));
    assert.equal((await getDoc(doc(tenant, 'rental_records/may:viewings:viewing-1'))).data().data.status, 'confirmed');
    await assertFails(updateDoc(doc(foreignOwner, 'rental_records/may:viewings:viewing-1'), {'data.status':'cancelled'}));
    await assertFails(updateDoc(doc(foreignOwner, 'rental_records/may:invoices:INV-1'), {'data.paidAmount':100000}));
    await assertFails(updateDoc(doc(tenant, 'rental_records/may:invoices:INV-1'), {'data.paidAmount':100000}));
    const payment = row('payments', {id:'payment-a',invoiceId:'INV-1',status:'pending',reportedAmount:100000,method:'Tiền mặt',reference:'',approvedAmount:null,reviewedAt:null,proofUrl:null});
    const cashRequest = writeBatch(tenant);
    cashRequest.update(doc(tenant, 'rental_records/may:invoices:INV-1'), {'data.pendingPaymentId':'payment-a'});
    cashRequest.set(doc(tenant, 'rental_records/may:payments:payment-a'), payment);
    await assertSucceeds(cashRequest.commit());
    const transferPayment = row('payments', {id:'payment-transfer',invoiceId:'INV-TRANSFER',status:'pending',reportedAmount:100000,method:'Chuyển khoản',reference:'TEST-NO-TRANSFER',approvedAmount:null,reviewedAt:null,proofUrl:'https://media.example/proof.jpg'});
    const transferRequest = writeBatch(tenant);
    transferRequest.update(doc(tenant, 'rental_records/may:invoices:INV-TRANSFER'), {'data.pendingPaymentId':'payment-transfer'});
    transferRequest.set(doc(tenant, 'rental_records/may:payments:payment-transfer'), transferPayment);
    await assertSucceeds(transferRequest.commit());
    const competingPayment = row('payments', {id:'payment-competing',invoiceId:'INV-1',status:'pending',reportedAmount:50000,method:'Tiền mặt',reference:'',approvedAmount:null,reviewedAt:null,proofUrl:null});
    const competingRequest = writeBatch(tenant);
    competingRequest.update(doc(tenant, 'rental_records/may:invoices:INV-1'), {'data.pendingPaymentId':'payment-competing'});
    competingRequest.set(doc(tenant, 'rental_records/may:payments:payment-competing'), competingPayment);
    await assertFails(competingRequest.commit());
    await assertFails(setDoc(doc(other, 'rental_records/may:payments:payment-b'), payment));
    await assertFails(setDoc(doc(tenant, 'rental_records/may:payments:payment-c'), {...payment, data:{...payment.data,id:'payment-c',status:'approved',approvedAmount:100000}}));
    await assertFails(updateDoc(doc(tenant, 'rental_records/may:payments:payment-a'), {'data.status':'approved'}));
    const cashCancel = writeBatch(tenant);
    cashCancel.update(doc(tenant, 'rental_records/may:payments:payment-a'), {'data.status':'cancelled','data.reviewedAt':'2026-11-25T10:01:00.000Z'});
    cashCancel.update(doc(tenant, 'rental_records/may:invoices:INV-1'), {'data.pendingPaymentId':null});
    await assertSucceeds(cashCancel.commit());
    const staleApprove = writeBatch(owner);
    staleApprove.update(doc(owner, 'rental_records/may:payments:payment-a'), {'data.status':'approved','data.approvedAmount':100000,'data.reviewedAt':'2026-11-25T10:02:00.000Z'});
    staleApprove.update(doc(owner, 'rental_records/may:invoices:INV-1'), {'data.paidAmount':100000,'data.pendingPaymentId':null,'data.lastApprovedPaymentId':'payment-a'});
    await assertFails(staleApprove.commit());
    const paymentB = row('payments', {id:'payment-b',invoiceId:'INV-1',status:'pending',reportedAmount:100000,method:'Tiền mặt',reference:'',approvedAmount:null,reviewedAt:null,proofUrl:null});
    const secondCashRequest = writeBatch(tenant);
    secondCashRequest.update(doc(tenant, 'rental_records/may:invoices:INV-1'), {'data.pendingPaymentId':'payment-b'});
    secondCashRequest.set(doc(tenant, 'rental_records/may:payments:payment-b'), paymentB);
    await assertSucceeds(secondCashRequest.commit());
    const cashApprove = writeBatch(owner);
    cashApprove.update(doc(owner, 'rental_records/may:payments:payment-b'), {'data.status':'approved','data.approvedAmount':100000,'data.reviewedAt':'2026-11-25T10:03:00.000Z'});
    cashApprove.update(doc(owner, 'rental_records/may:invoices:INV-1'), {'data.paidAmount':100000,'data.pendingPaymentId':null,'data.lastApprovedPaymentId':'payment-b'});
    await assertSucceeds(cashApprove.commit());
    const staleCancel = writeBatch(tenant);
    staleCancel.update(doc(tenant, 'rental_records/may:payments:payment-b'), {'data.status':'cancelled','data.reviewedAt':'2026-11-25T10:04:00.000Z'});
    staleCancel.update(doc(tenant, 'rental_records/may:invoices:INV-1'), {'data.pendingPaymentId':null});
    await assertFails(staleCancel.commit());
    const paymentC = row('payments', {id:'payment-c',invoiceId:'INV-1',status:'pending',reportedAmount:50000,method:'Tiền mặt',reference:'',approvedAmount:null,reviewedAt:null,proofUrl:null});
    const thirdCashRequest = writeBatch(tenant);
    thirdCashRequest.update(doc(tenant, 'rental_records/may:invoices:INV-1'), {'data.pendingPaymentId':'payment-c'});
    thirdCashRequest.set(doc(tenant, 'rental_records/may:payments:payment-c'), paymentC);
    await assertSucceeds(thirdCashRequest.commit());
    const secondCashApprove = writeBatch(owner);
    secondCashApprove.update(doc(owner, 'rental_records/may:payments:payment-c'), {'data.status':'approved','data.approvedAmount':50000,'data.reviewedAt':'2026-11-25T10:05:00.000Z'});
    secondCashApprove.update(doc(owner, 'rental_records/may:invoices:INV-1'), {'data.paidAmount':150000,'data.pendingPaymentId':null,'data.lastApprovedPaymentId':'payment-c'});
    await assertSucceeds(secondCashApprove.commit());
    await assertFails(updateDoc(doc(owner, 'rental_records/may:invoices:INV-1'), {'data.paidAmount':250000,'data.lastApprovedPaymentId':'payment-b'}));
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
    await assertSucceeds(updateDoc(doc(tenant, 'rental_records/may:leases:HD-1'), {
      'data.terminationRequestStatus':'pending',
      'data.terminationRequestedAt':'2026-11-25T10:00:00.000Z',
      'data.terminationRequestedBy':'tenant-a',
      'data.terminationRequestReason':'I need to move',
      'data.terminationReviewedAt':null,
      'data.terminationRejectionReason':'',
    }));
    await assertFails(updateDoc(doc(tenant, 'rental_records/may:leases:HD-1'), {'data.status':'terminated'}));
    await assertFails(updateDoc(doc(tenant, 'rental_records/may:leases:HD-1'), {'data.monthlyRent':1}));
    await assertFails(updateDoc(doc(tenant, 'rental_records/may:leases:HD-1'), {'data.terminationRequestStatus':'pending'}));
    await assertSucceeds(updateDoc(doc(tenant, 'rental_records/may:leases:HD-2'), {
      'data.renewalStatus':'pending',
      'data.renewalRequestedAt':'2026-11-25T10:06:00.000Z',
      'data.renewalRequestedBy':'tenant-a',
      'data.renewalProposedEndDate':'2027-12-31T00:00:00.000Z',
      'data.renewalReason':'I would like to renew',
      'data.renewalReviewedAt':null,
      'data.renewalRejectionReason':'',
    }));
    await assertFails(updateDoc(doc(tenant, 'rental_records/may:leases:HD-2'), {'data.monthlyRent':1}));
    await assertSucceeds(updateDoc(doc(tenant, 'rental_records/may:members:member-1'), {
      'data.leaveReason':'I am moving out',
      'data.leaveRequestedAt':'2026-11-25T10:00:00.000Z',
      'data.leaveEffectiveAt':'2026-12-25T00:00:00.000Z',
      'data.leaveAcknowledgedAt':null,
    }));
    await assertFails(updateDoc(doc(tenant, 'rental_records/may:members:member-1'), {'data.status':'inactive'}));
    await assertSucceeds(setDoc(doc(admin, 'public_settings/viewings'), {acceptingViewings:false}));
    await assertFails(setDoc(doc(tenant, 'rental_records/viewing-blocked'), row('viewings', {tenantId:'tenant-a',status:'pending'})));
    await assertSucceeds(setDoc(doc(admin, 'public_settings/viewings'), {acceptingViewings:true}));
    await assertSucceeds(setDoc(doc(tenant, 'rental_records/viewing-open'), row('viewings', {tenantId:'tenant-a',status:'pending'})));
    await assertSucceeds(updateDoc(doc(owner, 'rental_records/may:invoices:INV-1'), {'data.cancelled':true}));
    await assertFails(setDoc(doc(tenant, 'rental_records/payment-cancelled-invoice'), payment));
    await assertSucceeds(updateDoc(doc(owner, 'rental_records/may:leases:HD-1'), {'data.status':'terminated'}));
    await assertFails(setDoc(doc(tenant, 'rental_records/member-ended-lease'), row('members', {leaseId:'HD-1',tenantId:'MEMBER01',requestedBy:'tenant-a',status:'pending',isRepresentative:false})));
    await assertSucceeds(getDoc(doc(admin, 'rental_records/may:leases:HD-1')));
    assert.equal((await getDoc(doc(owner, 'rental_records/may:payments:payment-a'))).data().data.status, 'cancelled');
    assert.equal((await getDoc(doc(owner, 'rental_records/may:payments:payment-b'))).data().data.status, 'approved');
    assert.equal((await getDoc(doc(owner, 'rental_records/may:invoices:INV-1'))).data().data.paidAmount, 150000);
    console.log('RULES_CHECKS_PASSED: public catalog, scoped queries, role escalation, cross-user isolation, payment approval and immutable messages');
  } finally { await env.cleanup(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
