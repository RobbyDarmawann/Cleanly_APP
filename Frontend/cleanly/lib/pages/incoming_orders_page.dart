import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cleanly/config/api_config.dart';
import 'dart:convert';

class IncomingOrdersPage extends StatefulWidget {
  final VoidCallback onOrderActionCompleted;

  const IncomingOrdersPage({super.key, required this.onOrderActionCompleted});

  @override
  _IncomingOrdersPageState createState() => _IncomingOrdersPageState();
}

class _IncomingOrdersPageState extends State<IncomingOrdersPage> {
  List<dynamic> _incomingOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchIncomingOrders();
  }

  Future<void> _fetchIncomingOrders() async {
    setState(() {
      _isLoading = true;
    });

    const apiUrl = '${ApiConfig.baseUrl}/api/admin/incoming-orders';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _incomingOrders = data['orders'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengambil pesanan masuk.')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koneksi gagal.')),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    final apiUrl = '${ApiConfig.baseUrl}/api/admin/orders/$orderId/next-status';
    
    // Tambahkan logging yang lebih jelas
    print('--- LOG PERMINTAAN DARI FLUTTER ---');
    print('Mengirim update untuk Order ID: $orderId');
    print('Status baru yang dikirim: $newStatus');
    print('URL API: $apiUrl');
    print('--- AKHIR LOG ---');
    
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'newStatus': newStatus}),
      );

      // Log respons dari server
      print('--- LOG RESPON DARI SERVER ---');
      print('Respons dari server: ${response.statusCode}');
      print('Body respons: ${response.body}');
      print('--- AKHIR LOG ---');

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pesanan berhasil ${newStatus == 'Pesanan Diterima' ? 'diterima' : 'ditolak'}.')),
          );
          await _fetchIncomingOrders();
          widget.onOrderActionCompleted();
        }
      } else {
        if (mounted) {
          final errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal memperbarui status pesanan.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koneksi gagal.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Masuk'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _incomingOrders.isEmpty
              ? const Center(child: Text('Tidak ada pesanan masuk.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _incomingOrders.length,
                  itemBuilder: (context, index) {
                    final order = _incomingOrders[index];
                    return _IncomingOrderCard(
                      order: order,
                      onAccept: () => _updateOrderStatus(order['orderId'], 'Pesanan Diterima'),
                      onReject: () => _updateOrderStatus(order['orderId'], 'Ditolak'),
                    );
                  },
                ),
    );
  }
}

class _IncomingOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _IncomingOrderCard({
    required this.order,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final user = order['userId'];
    final orderDate = DateTime.parse(order['orderDate']);
    final formattedDate = '${orderDate.day} ${orderDate.month} ${orderDate.year}';
    final formattedTime = '${orderDate.hour.toString().padLeft(2, '0')}:${orderDate.minute.toString().padLeft(2, '0')}';
    final displayOrderId = order['orderId'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage('image/profil.png'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    user['namaLengkap'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text('$formattedDate, $formattedTime'),
              ],
            ),
            const SizedBox(height: 10),
            _buildDetailRow('Jenis Layanan', order['service']),
            _buildDetailRow('Kain Kotor Dijemput Kurir/Diantar Sendiri', order['pickupOption']),
            _buildDetailRow('Cucian Bersih Diantar Kurir/Dijemput Sendiri', order['deliveryOption']),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Terima', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('Tolak', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}