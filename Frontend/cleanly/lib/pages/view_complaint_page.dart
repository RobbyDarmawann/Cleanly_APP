import 'package:flutter/material.dart';

class ViewComplaintPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const ViewComplaintPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final String description = order['complaintDescription'] ?? 'Tidak ada deskripsi.';
    final String imageUrl = order['complaintImageUrl'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Komplain ${order['orderId']}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deskripsi Masalah:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),

            if (imageUrl.isNotEmpty) ...[
              const Text(
                'Foto Terlampir:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  // Menampilkan loading indicator saat gambar dimuat
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  // Menampilkan ikon error jika gambar gagal dimuat
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, color: Colors.red, size: 50);
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}