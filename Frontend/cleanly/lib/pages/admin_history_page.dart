import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cleanly/pages/admin_order_details_page.dart';
import 'package:cleanly/config/api_config.dart';

class AdminHistoryPage extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const AdminHistoryPage({super.key, required this.adminData});

  @override
  _AdminHistoryPageState createState() => _AdminHistoryPageState();
}

class _AdminHistoryPageState extends State<AdminHistoryPage> {
  List<dynamic> _completedOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompletedOrders();
  }

  Future<void> _fetchCompletedOrders() async {
    setState(() => _isLoading = true);
    const apiUrl = '${ApiConfig.baseUrl}/api/admin/completed-orders';

    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 15));
      if (mounted) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _completedOrders = data['orders'];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print("Error fetching completed orders: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan Selesai'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _completedOrders.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada pesanan yang selesai.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchCompletedOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _completedOrders.length,
                    itemBuilder: (context, index) {
                      final order = _completedOrders[index];
                      return _CompletedOrderCard(
                        order: order,
                        adminData: widget.adminData,
                      );
                    },
                  ),
                ),
    );
  }
}

class _CompletedOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic> adminData;

  const _CompletedOrderCard({required this.order, required this.adminData});

  @override
  Widget build(BuildContext context) {
    final user = order['userId'];
    final orderDate = DateTime.parse(order['orderDate']);
    final formattedDate = DateFormat('d MMM yyyy', 'id_ID').format(orderDate);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminOrderDetailsPage(
                order: order,
                adminData: adminData,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['orderId'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(user != null ? user['namaLengkap'] : 'Pelanggan Dihapus'),
                    Text('Layanan: ${order['service']}'),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rp ${order['price']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}