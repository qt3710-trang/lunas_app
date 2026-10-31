// API Node.js đọc kiểu tóc từ Firestore.
// Cài:  npm install express cors firebase-admin
// Chạy: node server.js   (cần serviceAccountKey.json cùng thư mục)
const express = require('express');
const cors = require('cors');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Trên Vercel: khóa nằm trong biến môi trường FIREBASE_SERVICE_ACCOUNT.
// Ở máy bạn: vẫn dùng file serviceAccountKey.json như cũ.
const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT
  ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
  : require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount),
});
const db = getFirestore();

const app = express();
app.use(cors());
app.use(express.json());

// GET /hair-styles          -> toàn bộ kiểu tóc, xếp theo lượt thích giảm dần
// GET /hair-styles?q=bob    -> tìm theo tên
// (Lọc theo độ dài, kiểu, màu, dịp do app Flutter tự làm trên danh sách này)
app.get('/hair-styles', async (req, res) => {
  try {
    const snap = await db.collection('hair_styles').get();
    let list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));

    const { q } = req.query;
    if (q) {
      const k = String(q).toLowerCase();
      list = list.filter((s) => String(s.name || '').toLowerCase().includes(k));
    }
    list.sort((a, b) => (b.likes || 0) - (a.likes || 0));
    res.json(list);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'Lỗi server' });
  }
});

// GET /hair-styles/bob-ngan
app.get('/hair-styles/:id', async (req, res) => {
  try {
    const doc = await db.collection('hair_styles').doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Không tìm thấy' });
    res.json({ id: doc.id, ...doc.data() });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'Lỗi server' });
  }
});

// Ở máy: node server.js -> mở cổng 3000. Trên Vercel: chỉ xuất app ra, Vercel tự chạy.
if (require.main === module) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => console.log('API chạy ở cổng', PORT));
}
module.exports = app;
