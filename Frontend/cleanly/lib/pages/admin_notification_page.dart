import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cleanly/config/api_config.dart';
import 'package:cleanly/pages/incoming_orders_page.dart'; // <-- Import baru

class AdminNotificationPage extends StatefulWidget {
  final String adminId;
  final VoidCallback onNavigatedBack;

  const AdminNotificationPage({super.key, required this.adminId, required this.onNavigatedBack});

  @override
  _AdminNotificationPageState createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final getUrl = '${ApiConfig.baseUrl}/api/notifications/${widget.adminId}';
    try {
      final response = await http.get(Uri.parse(getUrl));
      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _notifications = data['notifications'];
          _isLoading = false;
        });
        _markNotificationsAsRead();
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markNotificationsAsRead() async {
    final postUrl = '${ApiConfig.baseUrl}/api/notifications/mark-read/${widget.adminId}';
    try {
      await http.post(Uri.parse(postUrl));
      widget.onNavigatedBack();
    } catch (e) { /* handle error */ }
  }

  // --- FUNGSI BARU UNTUK MENGHAPUS NOTIFIKASI ---
  Future<void> _deleteNotification(String notificationId) async {
    final deleteUrl = '${ApiConfig.baseUrl}/api/notifications/$notificationId';
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
      appBar: AppBar(title: const Text('Notifikasi Admin')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('Tidak ada notifikasi.'))
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final notificationId = notif['_id'];

                      // --- PERBAIKAN UTAMA: BUNGKUS DENGAN DISMISSIBLE ---
                      return Dismissible(
                        key: Key(notificationId), 
                        direction: DismissDirection.startToEnd, 
                        onDismissed: (direction) {
                          _deleteNotification(notificationId);
                          setState(() {
                            _notifications.removeAt(index);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notifikasi dihapus')),
                          );
                        },
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
                        child: _AdminNotificationCard(
                          notification: notif,
                          onRefresh: _fetchNotifications, // Kirim fungsi refresh
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _AdminNotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onRefresh; // Terima fungsi refresh
  const _AdminNotificationCard({required this.notification, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(DateTime.parse(notification['createdAt']));
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell( // <-- PERBAIKAN: Bungkus dengan InkWell agar bisa ditekan
        borderRadius: BorderRadius.circular(15),
        onTap: () async {
          // Navigasi ke halaman pesanan masuk, tunggu sampai halaman ditutup
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IncomingOrdersPage(onOrderActionCompleted: onRefresh),
            ),
          );
          // Refresh halaman notifikasi setelah kembali
          onRefresh();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.receipt_long, color: Colors.white),
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
      ),
    );
  }
}