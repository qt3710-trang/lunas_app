// API Node.js cho app LUNAS: kiểu tóc + hồ sơ người dùng (Firestore).
// Cài:  npm install express cors firebase-admin@13
// Chạy: node server.js   (cần serviceAccountKey.json cùng thư mục)
//
// LƯU Ý: dùng firebase-admin bản 13. Bản 14 bị lỗi ERR_REQUIRE_ESM trên Vercel
// khi dùng phần kiểm tra token (getAuth).
const express = require('express');
const cors = require('cors');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

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

// =====================================================================
// KIỂU TÓC (ai cũng xem được, không cần đăng nhập)
// =====================================================================

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

// =====================================================================
// HỒ SƠ NGƯỜI DÙNG (cần đăng nhập)
// App gửi kèm header:  Authorization: Bearer <Firebase ID token>
// Mỗi người một tài liệu trong Firestore: users/{uid}
// =====================================================================

// "Người gác cổng": kiểm tra token Firebase. Hợp lệ -> biết uid, cho đi tiếp.
async function requireUser(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Chưa đăng nhập' });
  try {
    const decoded = await getAuth().verifyIdToken(token);
    req.uid = decoded.uid; // lấy từ token nên không giả mạo được
    next();
  } catch (e) {
    res.status(401).json({ error: 'Token không hợp lệ' });
  }
}

// Chỉ cho phép lưu các trường này (không cho app ghi linh tinh vào database).
// favorites = danh sách mã kiểu tóc đã bấm tim, ví dụ ["bob-han-quoc", "hush-cut"].
const PROFILE_FIELDS = [
  'name', 'favoriteHair', 'styleTags', 'faceShape', 'skinTone', 'weeklyNotify', 'favorites',
];

// GET /me -> hồ sơ của người đang đăng nhập (người mới: chỉ có id)
app.get('/me', requireUser, async (req, res) => {
  try {
    const doc = await db.collection('users').doc(req.uid).get();
    res.json(doc.exists ? { id: doc.id, ...doc.data() } : { id: req.uid });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'Lỗi server' });
  }
});

// PUT /me -> lưu hồ sơ (chỉ các trường trong PROFILE_FIELDS).
// Gửi trường nào thì cập nhật trường đó, các trường khác giữ nguyên (merge).
app.put('/me', requireUser, async (req, res) => {
  try {
    const data = {};
    for (const key of PROFILE_FIELDS) {
      if (key in req.body) data[key] = req.body[key];
    }

    // favorites phải là danh sách chữ; giữ tối đa 200 mẫu cho gọn.
    if ('favorites' in data) {
      if (!Array.isArray(data.favorites)) {
        return res.status(400).json({ error: 'favorites phải là danh sách' });
      }
      data.favorites = data.favorites
        .filter((x) => typeof x === 'string')
        .slice(0, 200);
    }

    await db.collection('users').doc(req.uid).set(data, { merge: true });
    res.json({ id: req.uid, ...data });
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