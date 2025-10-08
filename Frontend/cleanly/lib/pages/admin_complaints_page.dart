import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cleanly/pages/view_complaint_page.dart'; 
import 'package:cleanly/config/api_config.dart';

class AdminComplaintsPage extends StatefulWidget {
  const AdminComplaintsPage({super.key});

  @override
  _AdminComplaintsPageState createState() => _AdminComplaintsPageState();
}

class _AdminComplaintsPageState extends State<AdminComplaintsPage> {
  List<dynamic> _complaintsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    setState(() => _isLoading = true);
    const apiUrl = '${ApiConfig.baseUrl}/api/admin/complaints'; // Sesuaikan IP jika perlu

    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 15));
      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _complaintsList = data['complaints'];
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error fetching complaints: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Komplain Pelanggan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _complaintsList.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada komplain yang masuk.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchComplaints,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _complaintsList.length,
                    itemBuilder: (context, index) {
                      final complaint = _complaintsList[index];
                      return _ComplaintCard(order: complaint);
                    },
                  ),
                ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _ComplaintCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final user = order['userId'];

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user != null ? user['namaLengkap'] : 'Nama Pelanggan',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Order: ${order['orderId']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('Layanan: ${order['service']}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('Lihat Detail Komplain'),
                onPressed: () {
                  // Kita gunakan lagi halaman ViewComplaintPage yang sudah ada
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewComplaintPage(order: order),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}