import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cleanly/pages/home_page.dart';
import 'package:cleanly/config/api_config.dart';
import 'package:cleanly/pages/user_order_details_page.dart';


class HistoryPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HistoryPage({super.key, required this.userData});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> _historyOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistoryOrders();
  }

  Future<void> _fetchHistoryOrders() async {
    setState(() {
      _isLoading = true;
    });

    final apiUrl = '${ApiConfig.baseUrl}/api/history/${widget.userData['_id']}';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _historyOrders = data['orders'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengambil riwayat pesanan.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Riwayat Pesanan', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hari ini',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _historyOrders.isEmpty
                      ? const Center(child: Text('Tidak ada riwayat pesanan.'))
                      : Column(
                          children: _historyOrders.map((order) {
                            return _HistoryOrderCard(
                              order: order,
                            );
                          }).toList(),
                        ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage(userData: widget.userData)),
                );
              },
            ),
            IconButton(icon: const Icon(Icons.history, color: Color(0xFF2196F3)), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

class _HistoryOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _HistoryOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final orderId = order['orderId'] as String;
    final service = order['service'] as String;
    final date = order['orderDate'] as String;
    final price = order['price'];
    final orderDateTime = DateTime.parse(date);
    final formattedTime = '${orderDateTime.hour.toString().padLeft(2, '0')}:${orderDateTime.minute.toString().padLeft(2, '0')}';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.description, size: 50, color: Color(0xFF2196F3)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('order $orderId', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(service, style: const TextStyle(color: Colors.black54)),
                  const Text('Pesanan Selesai', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formattedTime, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 5),
                Text('Rp. $price', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        // Aksi untuk memberikan rating
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF06292),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Rating', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 5),
                    TextButton(
                      onPressed: () {
                        // Aksi untuk komplain
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF06292),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Komplain', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}