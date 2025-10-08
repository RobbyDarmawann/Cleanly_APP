import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cleanly/pages/user_order_details_page.dart';
import 'package:cleanly/pages/complaint_page.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cleanly/pages/view_complaint_page.dart';
import 'package:cleanly/config/api_config.dart';

class UserHistoryPage extends StatefulWidget {
  final String userId;

  const UserHistoryPage({super.key, required this.userId});

  @override
  _UserHistoryPageState createState() => _UserHistoryPageState();
}

class _UserHistoryPageState extends State<UserHistoryPage> {
  List<dynamic> _completedOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    final apiUrl = '${ApiConfig.baseUrl}/api/orders/${widget.userId}';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _completedOrders = (data['orders'] as List)
              .where((order) => order['status'] == 'Selesai')
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _completedOrders.isEmpty
              ? const Center(child: Text('Tidak ada riwayat pesanan.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _completedOrders.length,
                  itemBuilder: (context, index) {
                    return _UserCompletedOrderCard(order: _completedOrders[index]);
                  },
                ),
    );
  }
}

// Ganti seluruh kelas _UserCompletedOrderCard dengan ini

class _UserCompletedOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;

  const _UserCompletedOrderCard({required this.order});

  @override
  __UserCompletedOrderCardState createState() => __UserCompletedOrderCardState();
}

class __UserCompletedOrderCardState extends State<_UserCompletedOrderCard> {
  late double _currentRating;
  late bool _hasComplaint;

  @override
  void initState() {
    super.initState();
    _currentRating = (widget.order['rating'] ?? 0.0).toDouble();
    _hasComplaint = widget.order['complaintDescription'] != null && widget.order['complaintDescription'].isNotEmpty;
  }

  Future<void> _submitRating(double rating) async {
    final apiUrl = '${ApiConfig.baseUrl}/api/orders/${widget.order['orderId']}/rate';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rating': rating}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.statusCode == 200 ? 'Terima kasih atas penilaiannya!' : 'Gagal mengirim rating.'),
            backgroundColor: response.statusCode == 200 ? Colors.green : Colors.red,
          ),
        );
        if (response.statusCode == 200) {
          setState(() => _currentRating = rating);
        }
      }
    } catch (e) {
      // handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(widget.order['orderDate']));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.order['orderId'], style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.order['service']),
            Text('Rp ${widget.order['price']} - $formattedDate'),
            const Divider(height: 24),
            
            const Text('Beri Penilaian:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RatingBar.builder(
              initialRating: _currentRating,
              minRating: 1,
              direction: Axis.horizontal,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                _submitRating(rating);
              },
            ),
            const SizedBox(height: 16),
            
            // --- PERBAIKAN UTAMA: TOMBOL DINAMIS ---
            SizedBox(
              width: double.infinity,
              child: _hasComplaint
                  // JIKA SUDAH ADA KOMPLAIN: Tampilkan tombol "Lihat Komplain"
                  ? ElevatedButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('Lihat Komplain'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // Arahkan ke halaman detail komplain yang baru
                            builder: (context) => ViewComplaintPage(order: widget.order),
                          ),
                        );
                      },
                    )
                  // JIKA BELUM ADA KOMPLAIN: Tampilkan tombol "Ajukan Komplain"
                  : OutlinedButton.icon(
                      icon: const Icon(Icons.report_problem_outlined),
                      label: const Text('Ajukan Komplain'),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ComplaintPage(orderId: widget.order['orderId']),
                          ),
                        );

                        if (result == true) {
                          setState(() {
                            _hasComplaint = true;
                          });
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}