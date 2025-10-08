import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminOrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic> adminData;

  const AdminOrderDetailsPage({
    super.key,
    required this.order,
    required this.adminData,
  });

  @override
  Widget build(BuildContext context) {
    // Daftar semua kemungkinan status sesuai urutan proses
    final statuses = [
      'Pesanan Diterima Laundry',
      'Cucian Diterima Laundry',
      'Sedang Dikerjakan Laundry', // Anda bisa ganti dengan status yg lebih spesifik
      'Pesanan Dikirim Laundry',   // jika ada
      'Pesanan Laundry Selesai'
    ];
    
    final currentStatus = order['status'] as String;
    final int currentIndex = statuses.indexOf(currentStatus);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rincian Pesanan'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Tracker
            _StatusTracker(statuses: statuses, currentIndex: currentIndex),

            const SizedBox(height: 32),

            // Detail Pesanan
            _buildDetailCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    final customer = order['userId'];
    final orderDate = DateTime.parse(order['orderDate']);
    final formattedDate = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(orderDate);
    final formattedTime = DateFormat('HH:mm', 'id_ID').format(orderDate);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Kode Order', order['orderId'].toString()),
          _buildDetailRow('Pelanggan', customer['namaLengkap'] ?? '...'),
          _buildDetailRow('Jenis Layanan', order['service']),
          _buildDetailRow('Opsi Penjemputan', order['pickupOption']),
          _buildDetailRow('Opsi Pengantaran', order['deliveryOption']),
          _buildDetailRow('Total Harga', 'Rp ${order['price']}'),
          _buildDetailRow('Pesanan Dibuat', '$formattedDate, $formattedTime'),
          _buildDetailRow('Pesanan Selesai', order['status'] == 'Selesai' ? 'Sudah Selesai' : '-'),
          const Divider(height: 32),
          _buildDetailRow('Penanggung Jawab', adminData['namaLengkap'] ?? 'Admin', isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
              color: isHighlight ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}


class _StatusTracker extends StatelessWidget {
  final List<String> statuses;
  final int currentIndex;

  const _StatusTracker({required this.statuses, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(statuses.length, (index) {
        final bool isActive = index <= currentIndex;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 0 ? Colors.transparent : (isActive ? Colors.black : Colors.grey[300]),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? Colors.black : Colors.white,
                      border: Border.all(color: isActive ? Colors.black : Colors.grey[300]!, width: 2),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == statuses.length - 1 ? Colors.transparent : (isActive ? Colors.black : Colors.grey[300]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                statuses[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}