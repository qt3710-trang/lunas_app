// Đẩy hair_styles.json lên Firestore (collection "hair_styles").
// Cách chạy:
//   npm install firebase-admin
//   (đặt serviceAccountKey.json cùng thư mục, KHÔNG commit file này lên git)
//   node seed.js            -> thêm / ghi đè các kiểu tóc có trong file JSON
//   node seed.js --clean    -> như trên, và XÓA các kiểu tóc cũ không còn trong file JSON
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const styles = require('./hair_styles.json');

initializeApp({
  credential: cert(require('./serviceAccountKey.json')),
});
const db = getFirestore();
const clean = process.argv.includes('--clean');

(async () => {
  const col = db.collection('hair_styles');
  const batch = db.batch();

  for (const s of styles) {
    const { id, ...data } = s;
    batch.set(col.doc(id), data); // set = ghi đè hoàn toàn document cùng id
  }

  let removed = 0;
  if (clean) {
    const keep = new Set(styles.map((s) => s.id));
    const snap = await col.get();
    snap.docs.forEach((d) => {
      if (!keep.has(d.id)) {
        batch.delete(d.ref);
        removed++;
      }
    });
  }

  await batch.commit();
  console.log('Đã đẩy', styles.length, 'kiểu tóc lên Firestore');
  if (clean) console.log('Đã xóa', removed, 'kiểu tóc cũ không còn trong file');
})();
