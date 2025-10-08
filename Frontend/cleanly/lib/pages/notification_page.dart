import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cleanly/config/api_config.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  final String userId;
  final VoidCallback onNavigatedBack; // Callback untuk refresh ikon

  const NotificationPage({super.key, required this.userId, required this.onNavigatedBack});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    // 1. Ambil data notifikasi
    final getUrl = '${ApiConfig.baseUrl}/api/notifications/${widget.userId}';
    try {
      final response = await http.get(Uri.parse(getUrl));
      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _notifications = data['notifications'];
          _isLoading = false;
        });
        // 2. Setelah berhasil, tandai semua sudah dibaca
        _markNotificationsAsRead();
      }
    } catch (e) { /* handle error */ }
  }

  Future<void> _markNotificationsAsRead() async {
    final postUrl = '${ApiConfig.baseUrl}/api/notifications/mark-read/${widget.userId}';
    try {
      await http.post(Uri.parse(postUrl));
      widget.onNavigatedBack(); // Panggil callback untuk refresh ikon di home
    } catch (e) { /* handle error */ }
  }

  Future<void> _deleteNotification(String notificationId) async {
    final deleteUrl = '${ApiConfig.baseUrl}/api/notifications/$notificationId'; // Sesuaikan IP
    try {
      final response = await http.delete(Uri.parse(deleteUrl));
      if (response.statusCode == 200) {
        print('Notifikasi $notificationId berhasil dihapus dari server.');
      } else {
        print('Gagal menghapus notifikasi dari server.');
      }
    } catch (e) {
      print("Error deleting notification: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('Tidak ada notifikasi.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final notificationId = notif['_id']; // Ambil _id unik dari notifikasi

                    // --- PERBAIKAN UTAMA: BUNGKUS DENGAN DISMISSIBLE ---
                    return Dismissible(
                      // Key unik untuk setiap item, penting untuk Dismissible
                      key: Key(notificationId), 
                      
                      // Arah geser: hanya dari kiri ke kanan
                      direction: DismissDirection.startToEnd, 
                      
                      // Callback yang dijalankan setelah item digeser penuh
                      onDismissed: (direction) {
                        // Hapus dari server di background
                        _deleteNotification(notificationId);

                        // Hapus dari UI secara instan
                        setState(() {
                          _notifications.removeAt(index);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notifikasi dihapus')),
                        );
                      },

                      // Tampilan yang muncul di belakang kartu saat digeser
                      background: Container(
                        color: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerLeft,
                        child: const Row(
                          children: [
                            Icon(Icons.delete, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      
                      // Widget asli yang ditampilkan
                      child: _NotificationCard(notification: notif),
                    );
                  },
                ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(DateTime.parse(notification['createdAt']));
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Ganti ikon berdasarkan judul notifikasi jika perlu
            const CircleAvatar(
              radius: 24,
              child: Icon(Icons.notifications),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(notification['message'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}