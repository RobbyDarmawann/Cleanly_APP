import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserOrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const UserOrderDetailsPage({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    // Daftar status pesanan sesuai urutan prosesnya
    final statuses = [
      'Pesanan Diterima',
      'Cucian Diterima',
      'Sedang Dikerjakan',
      'Sedang Dikirim',
      'Pesanan Selesai'
    ];
    
    final currentStatus = orderData['status'] as String;
    // Cari index dari status saat ini, jika tidak ketemu anggap -1 (belum mulai)
    final int currentIndex = statuses.indexOf(currentStatus);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rincian Pesanan'),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
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
    final orderDate = DateTime.parse(orderData['orderDate']);
    // Format tanggal dan waktu menggunakan package intl
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
          _buildDetailRow('Kode Order', orderData['orderId'].toString()),
          _buildDetailRow('Jenis Layanan', orderData['service']),
          _buildDetailRow('Opsi Penjemputan', orderData['pickupOption']),
          _buildDetailRow('Opsi Pengantaran', orderData['deliveryOption']),
          _buildDetailRow('Total Harga', 'Rp ${orderData['price']}'),
          _buildDetailRow('Pesanan Dibuat', '$formattedDate, $formattedTime'),
          _buildDetailRow('Pesanan Selesai', orderData['status'] == 'Selesai' ? 'Sudah Selesai' : '-'),
        ],
      ),
    );
  }

  // Widget bantuan untuk menampilkan baris detail
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget untuk menampilkan progress bar status pesanan
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
                  Expanded(child: Container(height: 2, color: index == 0 ? Colors.transparent : (isActive ? Colors.black : Colors.grey[300]))),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? Colors.black : Colors.white,
                      border: Border.all(color: isActive ? Colors.black : Colors.grey[300]!, width: 2),
                    ),
                  ),
                  Expanded(child: Container(height: 2, color: index == statuses.length - 1 ? Colors.transparent : (isActive ? Colors.black : Colors.grey[300]))),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                statuses[index],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
              ),
            ],
          ),
        );
      }),
    );
  }
}