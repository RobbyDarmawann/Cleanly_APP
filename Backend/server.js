const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

// 1. Koneksi ke MongoDB
mongoose.connect('mongodb://localhost:27017/cleanly-laundry', {
    useNewUrlParser: true,
    useUnifiedTopology: true,
})
.then(() => console.log(' Terkoneksi ke MongoDB'))
.catch(err => console.error(' Gagal terkoneksi ke MongoDB', err));

// 2. Middleware
app.use(bodyParser.json());

// 3. Models
const userSchema = new mongoose.Schema({
    namaLengkap: String,
    email: { type: String, required: true, unique: true },
    noTelepon: String,
    alamat: String,
    kataSandi: String,
    role: { type: String, default: 'user' }
});
const User = mongoose.model('User', userSchema);

const orderSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    orderId: { type: String, required: true, unique: true },
    service: { type: String, required: true },
    pickupOption: { type: String, required: true },
    deliveryOption: { type: String, required: true },
    orderDate: { type: Date, default: Date.now },
    price: { type: Number, default: 0 },
    weight: { type: Number, default: 0 },
    status: { type: String, default: 'Pesanan Masuk' },
    rating: { type: Number, min: 0, max: 5, default: 0 },
    paymentMethod: { type: String, default: '' }, // Akan diisi 'COD'
    paymentStatus: { type: String, default: 'Belum Dibayar' },
    complaintDescription: { type: String, default: '' },
    complaintImageUrl: { type: String, default: '' },
    }, { timestamps: true });


const Order = mongoose.model('Order', orderSchema);
const { startOfDay, endOfDay, startOfWeek, endOfWeek, startOfMonth, endOfMonth, startOfYear, endOfYear } = require('date-fns');

// server.js -> setelah model Counter

// --- MODEL BARU UNTUK NOTIFIKASI ---
const notificationSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    orderId: { type: String, required: true },
    title: { type: String, required: true },
    message: { type: String, required: true },
    isRead: { type: Boolean, default: false },
}, { timestamps: true }); // timestamps: true akan otomatis menambahkan createdAt & updatedAt

const Notification = mongoose.model('Notification', notificationSchema);

const servicesSchema = new mongoose.Schema({
    type: { type: String, required: true, unique: true },
    price: { type: Number, required: true }
});
const Service = mongoose.model('Service', servicesSchema);

const counterSchema = new mongoose.Schema({
    _id: { type: String, required: true },
    sequence_value: { type: Number, default: 0 }
});
const Counter = mongoose.model('Counter', counterSchema);

// 4. Helper Function untuk Auto-Increment
async function getNextSequenceValue(sequenceName) {
    const sequenceDocument = await Counter.findByIdAndUpdate(
        sequenceName,
        { $inc: { sequence_value: 1 } },
        { new: true, upsert: true }
    );
    return sequenceDocument.sequence_value;
}


// 5. Routes / Endpoints
// Rute utama untuk cek server
app.get('/', (req, res) => {
    res.send('Server Cleanly berjalan dengan sukses!');
});

// Endpoint Registrasi
app.post('/api/register', async (req, res) => {
    try {
        const newUser = new User(req.body);
        await newUser.save();
        res.status(201).send({ message: 'Registrasi berhasil!', user: newUser });
    } catch (error) {
        res.status(400).send({ message: 'Registrasi gagal.', error: error.message });
    }
});

// Endpoint Login
app.post('/api/login', async (req, res) => {
    try {
        const { email, kataSandi } = req.body;
        const user = await User.findOne({ email });
        if (!user || user.kataSandi !== kataSandi) {
            return res.status(401).send({ message: 'Email atau kata sandi salah.' });
        }
        res.status(200).send({ message: 'Login berhasil!', user });
    } catch (error) {
        res.status(500).send({ message: 'Gagal login. Silakan coba lagi.' });
    }
});

// Endpoint Membuat Pesanan Baru
app.post('/api/order', async (req, res) => {
    try {
        const { userId, service, pickupOption, deliveryOption } = req.body;
        const nextOrderNumber = await getNextSequenceValue('orderId');
        const newOrderId = 'ORDER-' + nextOrderNumber;
        
        const newOrder = new Order({
            userId,
            service,
            pickupOption,
            deliveryOption,
            orderId: newOrderId,
        });
        await newOrder.save();
        res.status(201).send({ message: 'Pesanan berhasil dibuat!', order: newOrder });
    } catch (error) {
        console.error('Error membuat pesanan:', error);
        res.status(400).send({ message: 'Gagal membuat pesanan.', error: error.message });
    }
});

// Endpoint Mengambil Pesanan Berdasarkan User ID
app.get('/api/orders/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const orders = await Order.find({ userId }).sort({ orderDate: -1 });
        res.status(200).send({ orders });
    } catch (error) {
        res.status(500).send({ message: 'Gagal mendapatkan data pesanan.', error: error.message });
    }
});

// --- ADMIN ENDPOINTS ---
app.post('/api/orders/:orderId/rate', async (req, res) => {
    try {
        const { orderId } = req.params;
        const { rating } = req.body;
        
        if (typeof rating !== 'number' || rating < 1 || rating > 5) {
            return res.status(400).send({ message: 'Rating tidak valid.' });
        }

        const updatedOrder = await Order.findOneAndUpdate(
            { orderId },
            { $set: { rating: rating } },
            { new: true }
        );

        if (!updatedOrder) return res.status(404).send({ message: 'Pesanan tidak ditemukan.' });
        res.status(200).send({ message: 'Terima kasih atas penilaian Anda!', order: updatedOrder });

    } catch (error) {
        res.status(500).send({ message: 'Gagal mengirim rating.', error: error.message });
    }
});


// Endpoint untuk mengirim komplain
app.post('/api/orders/:orderId/complain', async (req, res) => {
    try {
        const { orderId } = req.params;
        const { description, imageUrl } = req.body;

        // --- LOGIKA BARU DIMULAI DI SINI ---
        
        // 1. Cari pesanan terlebih dahulu
        const order = await Order.findOne({ orderId });

        if (!order) {
            return res.status(404).send({ message: 'Pesanan tidak ditemukan.' });
        }

        // 2. Cek apakah deskripsi komplain sudah ada isinya
        if (order.complaintDescription && order.complaintDescription.length > 0) {
            // Jika sudah ada, kirim error 409 Conflict (konflik data)
            return res.status(409).send({ message: 'Komplain untuk pesanan ini sudah pernah diajukan.' });
        }
        
        // --- LOGIKA BARU SELESAI ---

        // Jika belum ada komplain, lanjutkan proses update
        const updatedOrder = await Order.findOneAndUpdate(
            { orderId },
            { $set: { complaintDescription: description, complaintImageUrl: imageUrl } },
            { new: true }
        );

        if (!updatedOrder) return res.status(404).send({ message: 'Gagal mengupdate pesanan.' });
        
        res.status(200).send({ message: 'Komplain berhasil dikirim.', order: updatedOrder });

    } catch (error) {
        res.status(500).send({ message: 'Gagal mengirim komplain.', error: error.message });
    }
});
// Endpoint Mengambil Pesanan Masuk
app.get('/api/admin/incoming-orders', async (req, res) => { 
    try {
        const incomingOrders = await Order.find({ status: 'Pesanan Masuk' }).populate('userId');
        res.status(200).send({ orders: incomingOrders });
    } catch (error) {
        res.status(500).send({ message: 'Gagal mendapatkan pesanan masuk.', error: error.message });
    }
});

// Endpoint Mengambil Pesanan Berjalan
app.get('/api/admin/ongoing-orders', async (req, res) => {
    try {
        const ongoingOrders = await Order.find({ 
            status: { $in: [        
              'Pesanan Diterima', // <-- Ini yang dicari setelah pesanan diterima
              'Cucian Diterima Laundry', 
              'Sedang Dicuci', 
              'Sedang Dikerjakan',
              'Siap Dikirim/Diambil'] } 
        }).populate('userId').sort({ orderDate: -1 });
        res.status(200).send({ orders: ongoingOrders });
    } catch (error) {
        res.status(500).send({ message: 'Gagal mendapatkan pesanan yang sedang diproses.', error: error.message });
    }
});

// server.js

// Endpoint untuk mengambil notifikasi milik pengguna
app.get('/api/notifications/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const notifications = await Notification.find({ userId }).sort({ createdAt: -1 });
        res.status(200).send({ notifications });
    } catch (error) {
        res.status(500).send({ message: 'Gagal mengambil notifikasi.' });
    }
});

app.delete('/api/notifications/:notificationId', async (req, res) => {
    try {
        const { notificationId } = req.params;
        
        const deletedNotification = await Notification.findByIdAndDelete(notificationId);

        if (!deletedNotification) {
            return res.status(404).send({ message: 'Notifikasi tidak ditemukan.' });
        }

        res.status(200).send({ message: 'Notifikasi berhasil dihapus.' });
    } catch (error) {
        res.status(500).send({ message: 'Gagal menghapus notifikasi.', error: error.message });
    }
});

// Endpoint untuk menandai semua notifikasi sebagai sudah dibaca
app.post('/api/notifications/mark-read/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        await Notification.updateMany({ userId: userId, isRead: false }, { $set: { isRead: true } });
        res.status(200).send({ message: 'Semua notifikasi ditandai terbaca.' });
    } catch (error) {
        res.status(500).send({ message: 'Gagal menandai notifikasi.' });
    }
});


// Endpoint Mengubah Status (Terima/Tolak)
app.post('/api/admin/orders/:orderId/next-status', async (req, res) => {
    try {
        const { orderId } = req.params;
        const { newStatus } = req.body;
        
        let updateQuery = { status: newStatus };

        if (newStatus === 'Selesai') {
            updateQuery.paymentStatus = 'Lunas';
        }

        const updatedOrder = await Order.findOneAndUpdate(
            { orderId: orderId },
            { $set: updateQuery },
            { new: true }
        ).populate('userId');

        if (!updatedOrder) {
            return res.status(404).send({ message: 'Pesanan tidak ditemukan.' });
        }

        // Logika Notifikasi (setelah order berhasil diupdate)
        let notifTitle = '';
        let notifMessage = '';
        switch(newStatus) {
            case 'Pesanan Diterima':
                notifTitle = 'Pesanan anda diterima!';
                notifMessage = `Pesanan ${updatedOrder.service} dengan nomor order ${orderId} anda berhasil diterima.`;
                break;
            case 'Sedang Dicuci':
                notifTitle = 'Cucian Anda Sedang Dicuci';
                notifMessage = `Pesanan ${orderId} sedang dalam proses pencucian.`;
                break;
            // Tambahkan notifikasi untuk status lain jika perlu
        }
        if (notifTitle) {
            const newNotif = new Notification({
                userId: updatedOrder.userId._id,
                orderId: orderId,
                title: notifTitle,
                message: notifMessage,
            });
            await newNotif.save();
        }
        
        res.status(200).send({ message: `Status pesanan berhasil diperbarui`, order: updatedOrder });
    } catch (error) {
        console.error("Error updating status:", error);
        res.status(500).send({ message: 'Gagal memperbarui status pesanan.', error: error.message });
    }
});
// Endpoint Mengupdate Berat & Harga (INI YANG DIPERBAIKI)
app.put('/api/admin/orders/:orderId/update-price', async (req, res) => {
    try {
        const { orderId } = req.params;
        const { weight } = req.body;
        if (typeof weight !== 'number' || weight <= 0) {
            return res.status(400).send({ message: 'Berat harus angka dan lebih besar dari 0.' });
        }
        const order = await Order.findOne({ orderId });
        if (!order) {
            return res.status(404).send({ message: 'Pesanan tidak ditemukan.' });
        }
        
        const prices = await Service.find({});
        const priceMap = prices.reduce((map, item) => {
            map[item.type] = item.price;
            return map;
        }, {});
        
        let basePrice = 0;
        switch (order.service) {
            case 'Cuci & Lipat': basePrice = weight * (priceMap['cuci_lipat_per_kg'] || 0); break;
            case 'Cuci & Setrika': basePrice = weight * (priceMap['cuci_setrika_per_kg'] || 0); break;
            case 'Setrika saja': basePrice = weight * (priceMap['setrika_saja_per_kg'] || 0); break;
            case 'One Day Service': basePrice = weight * (priceMap['one_day_service_per_kg'] || 0); break;
        }

        const pickupFee = order.pickupOption === 'Dijemput Kurir' ? (priceMap['pickup'] || 0) : 0;
        const deliveryFee = order.deliveryOption === 'Diantar Kurir' ? (priceMap['delivery'] || 0) : 0;
        const totalPrice = basePrice + pickupFee + deliveryFee;

        const updatedOrder = await Order.findOneAndUpdate(
            { orderId },
            { $set: { weight, price: totalPrice, status: 'Cucian Diterima Laundry' } },
            { new: true }
        );

        // Logika Notifikasi (diletakkan setelah update berhasil)
        if (updatedOrder) {
             const notif = new Notification({
                userId: updatedOrder.userId,
                orderId: orderId,
                title: 'Tagihan Anda sudah Muncul!',
                message: `Tagihan untuk pesanan ${orderId} telah terbit. Segera lakukan pembayaran.`,
            });
            await notif.save();
        }

        res.status(200).send({ message: 'Harga dan berat berhasil diperbarui!', order: updatedOrder });
    } catch (error) {
        console.error("Error updating price:", error);
        res.status(500).send({ message: 'Gagal memperbarui harga pesanan.', error: error.message });
    }
});

app.post('/api/orders/:orderId/confirm-payment', async (req, res) => {
    try {
        const { orderId } = req.params;
        const { paymentMethod } = req.body;

        if (paymentMethod !== 'COD') {
            return res.status(400).send({ message: 'Metode pembayaran tidak valid.' });
        }

        const updatedOrder = await Order.findOneAndUpdate(
            { orderId },
            { $set: { 
                paymentMethod: paymentMethod,
                paymentStatus: 'Tagihan COD' // Status diubah menjadi "Tagihan COD"
            }},
            { new: true }
        );

        if (!updatedOrder) {
            return res.status(404).send({ message: 'Pesanan tidak ditemukan.' });
        }
        
        res.status(200).send({ message: 'Pembayaran dikonfirmasi!', order: updatedOrder });

    } catch (error) {
        console.error("Error confirming payment:", error);
        res.status(500).send({ message: 'Gagal konfirmasi pembayaran.', error: error.message });
    }
});

app.get('/api/admin/completed-orders', async (req, res) => {
    try {
        const completedOrders = await Order.find({ status: 'Selesai' })
            .populate('userId')
            .sort({ orderDate: -1 });
        res.status(200).send({ orders: completedOrders });
    } catch (error) {
        res.status(500).send({ message: 'Gagal mendapatkan riwayat pesanan.', error: error.message });
    }
});

app.get('/api/admin/complaints', async (req, res) => {
    try {
        // Cari pesanan yang field complaintDescription-nya tidak kosong
        const complaints = await Order.find({ 
            complaintDescription: { $ne: '' } 
        })
        .populate('userId') // Ambil data user (untuk nama)
        .sort({ updatedAt: -1 }); // Urutkan berdasarkan yang terbaru diupdate

        res.status(200).send({ complaints });
    } catch (error) {
        res.status(500).send({ message: 'Gagal mengambil data komplain.', error: error.message });
    }
});

app.get('/api/admin/revenue', async (req, res) => {
    const { filter } = req.query; // filter=daily, weekly, monthly, yearly, yearly_detail

    try {
        let matchQuery = { status: 'Selesai' };
        const now = new Date();

        if (filter === 'daily') {
            matchQuery.updatedAt = { $gte: startOfDay(now), $lte: endOfDay(now) };
        } else if (filter === 'weekly') {
            matchQuery.updatedAt = { $gte: startOfWeek(now), $lte: endOfWeek(now) };
        } else if (filter === 'monthly') {
            matchQuery.updatedAt = { $gte: startOfMonth(now), $lte: endOfMonth(now) };
        } else if (filter === 'yearly' || filter === 'yearly_detail') {
            matchQuery.updatedAt = { $gte: startOfYear(now), $lte: endOfYear(now) };
        }

        let result;
        if (filter === 'yearly_detail') {
            // Rincian pendapatan per bulan dalam setahun
            result = await Order.aggregate([
                { $match: matchQuery },
                {
                    $group: {
                        _id: { month: { $month: "$updatedAt" } }, // Grup berdasarkan bulan
                        total: { $sum: "$price" }
                    }
                },
                { $sort: { "_id.month": 1 } } // Urutkan dari Januari (1) ke Desember (12)
            ]);
        } else {
            // Total pendapatan untuk periode yang dipilih
            result = await Order.aggregate([
                { $match: matchQuery },
                {
                    $group: {
                        _id: null,
                        total: { $sum: "$price" }
                    }
                }
            ]);
        }
        
        res.status(200).send(result);

    } catch (error) {
        console.error("Error fetching revenue:", error);
        res.status(500).send({ message: 'Gagal mengambil data pendapatan.', error: error.message });
    }
});

// 6. Jalankan Server
app.listen(port, '0.0.0.0', () => {
    console.log(`🚀 Server berjalan di http://localhost:${port}`);
});