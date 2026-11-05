// Explicit live check: only creates/edits/archives its own crud-check-* records.
const fs = require('node:fs');
const assert = require('node:assert/strict');
const { initializeApp, deleteApp } = require('../.dart_tool/firebase_tools/node_modules/firebase/app');
const { getAuth, signInWithEmailAndPassword, signOut } = require('../.dart_tool/firebase_tools/node_modules/firebase/auth');
const { getFirestore, doc, collection, getDocs, getDocFromServer, runTransaction, onSnapshot, query, where } = require('../.dart_tool/firebase_tools/node_modules/firebase/firestore');

(async () => {
  assert(process.argv.includes('--apply'), 'Live check requires --apply');
  const config = fs.readFileSync('lib/firebase_options.dart', 'utf8').match(/FirebaseOptions web\s*=\s*FirebaseOptions\((.*?)\);/s)[1];
  const app = initializeApp(Object.fromEntries(['apiKey','appId','messagingSenderId','projectId'].map(key =>
    [key, config.match(new RegExp(key + ":\\s*'([^']+)'"))[1]])));
  const auth = getAuth(app), db = getFirestore(app);
  const fixture = JSON.parse(fs.readFileSync('.dart_tool/property_crud_check/export.json', 'utf8'));
  assert(/^crud-check-\d+$/.test(fixture.propertyId));
  let created = false, archived = false, unsubscribe;
  const archivedData = data => data.kind ? {...data, archived: true}
    : 'roomCode' in data ? {...data, published: false, available: false} : {...data, archived: true};
  try {
    const credential = await signInWithEmailAndPassword(auth, process.env.CRUD_ADMIN_EMAIL, process.env.CRUD_ADMIN_PASSWORD);
    delete process.env.CRUD_ADMIN_PASSWORD;
    const profile = (await getDocFromServer(doc(db, 'users', credential.user.uid))).data();
    assert(profile?.role === 'admin' && profile.disabled === false);
    const properties = await getDocs(collection(db, 'rental_properties'));
    const owner = properties.docs.find(p => !p.data().archived)?.data().ownerUid;
    const ownerProfile = (await getDocFromServer(doc(db, 'users', owner))).data();
    assert(ownerProfile?.role === 'landlord' && ownerProfile.disabled === false);
    for (const operation of ['create','update']) {
      for (const [path,data] of Object.entries(fixture[operation])) {
        assert(path === `rental_properties/${fixture.propertyId}` || data.propertyId === fixture.propertyId);
        data.ownerUid = owner;
      }
    }
    const backup = '.local-backups/firestore/' + fixture.propertyId;
    fs.mkdirSync(backup, {recursive: true});
    fs.writeFileSync(backup+'/planned.json', JSON.stringify(fixture));
    let resolveChange;
    const recordChange = new Promise(resolve => { resolveChange = resolve; });
    await new Promise((resolve, reject) => {
      let initialized = false;
      unsubscribe = onSnapshot(query(collection(db, 'rental_records'), where('propertyId','==',fixture.propertyId)), snapshot => {
        if (!initialized) { initialized = true; resolve(); }
        if (!snapshot.empty && snapshot.docs.some(d => d.data().data.listenerCheck === true)) resolveChange();
      }, reject);
    });
    for (const operation of ['create','update','archive']) {
      const payload = operation === 'archive' ? Object.fromEntries(Object.entries(fixture.update).map(([p,d]) => [p,archivedData(d)])) : fixture[operation];
      await runTransaction(db, async tx => {
        const entries = Object.entries(payload);
        const live = await Promise.all(entries.map(([p]) => tx.get(doc(db,p))));
        entries.forEach(([path,data], index) => {
          if (operation === 'create') assert(!live[index].exists(), 'Refuse existing document');
          else assert.deepEqual(live[index].data(), fixture[operation === 'update' ? 'create' : 'update'][path]);
          tx.set(doc(db,path),data);
        });
      });
      if (operation === 'create') created = true;
      if (operation === 'archive') archived = true;
      for (const [path,expected] of Object.entries(payload)) {
        assert.deepEqual((await getDocFromServer(doc(db,path))).data(),expected);
      }
      fs.writeFileSync(backup+'/'+operation+'-verified.json',JSON.stringify(payload));
      console.log(operation.toUpperCase()+'_READ_BACK_OK: '+Object.keys(payload).length);
      if (operation === 'update') {
        const path = Object.keys(fixture.update).find(p => p.startsWith('rental_records/'));
        fixture.update[path].data.listenerCheck = true;
        await runTransaction(db, async tx => {
          await tx.get(doc(db,path));
          tx.set(doc(db,path), fixture.update[path]);
        });
        let timeout;
        try {
          await Promise.race([recordChange, new Promise((_,reject) => {
            timeout = setTimeout(() => reject(new Error('Record listener timed out')),15000);
          })]);
        } finally { clearTimeout(timeout); }
        console.log('RECORD_ONLY_LIVE_UPDATE_OK');
      }
    }
    console.log('LIVE_PROPERTY_CRUD_VERIFIED: '+fixture.propertyId);
  } finally {
    unsubscribe?.();
    if (created && !archived) {
      await runTransaction(db, async tx => {
        const refs = Object.keys(fixture.create).map(p => doc(db,p));
        const live = await Promise.all(refs.map(ref => tx.get(ref)));
        live.forEach((snap,i) => { if (snap.exists()) tx.set(refs[i],archivedData(snap.data())); });
      });
    }
    await signOut(auth);
    await deleteApp(app);
  }
})().catch(error => { console.error(error.code || error.message); process.exitCode = 1; });
