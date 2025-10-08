import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cleanly/pages/incoming_orders_page.dart';
import 'package:cleanly/pages/profile_admin_page.dart';
import 'package:cleanly/pages/input_weight_page.dart';
import 'package:cleanly/pages/admin_order_details_page.dart';
import 'package:cleanly/pages/admin_history_page.dart';
import 'package:cleanly/config/api_config.dart';
import 'package:cleanly/pages/admin_complaints_page.dart';
import 'package:intl/intl.dart';

class HomePageAdmin extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomePageAdmin({super.key, required this.userData});

  @override
  _HomePageAdminState createState() => _HomePageAdminState();
}

class _HomePageAdminState extends State<HomePageAdmin> {
  int _incomingOrderCount = 0;
  List<dynamic> _ongoingOrders = [];
  bool _isLoadingIncoming = true;
  bool _isLoadingOngoing = true;

 String _selectedFilter = 'minggu_ini';
  double _totalRevenue = 0;
  List<Map<String, dynamic>> _monthlyRevenue = [];
  bool _isLoadingRevenue = true;
  String _cardTitle = 'Pendapatan Minggu Ini';
  final Map<String, String> _filters = {
    'hari_ini': 'daily',
    'minggu_ini': 'weekly',
    'bulan_ini': 'monthly',
    'tahun_ini': 'yearly',
  };
  
  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    await Future.wait([
      _fetchIncomingOrdersCount(),
      _fetchOngoingOrders(),
      _fetchRevenue(_filters[_selectedFilter]!, isYearlyDetail: _selectedFilter == 'tahun_ini'),
    ]);
  }
   Future<void> _fetchRevenue(String filter, {bool isYearlyDetail = false}) async {
    if (!mounted) return;
    setState(() => _isLoadingRevenue = true);
    final endpoint = isYearlyDetail ? 'yearly_detail' : filter;
    final apiUrl = '${ApiConfig.baseUrl}/api/admin/revenue?filter=$endpoint';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (isYearlyDetail) {
            _monthlyRevenue = List<Map<String, dynamic>>.from(data.map((item) => {'month': item['_id']['month'], 'total': item['total']}));
            _totalRevenue = _monthlyRevenue.fold(0, (sum, item) => sum + item['total']);
          } else {
            _totalRevenue = (data.isNotEmpty ? data[0]['total'] : 0).toDouble();
            if(filter != 'yearly') {
               _monthlyRevenue.clear();
            }
          }
        });
      }
    } catch (e) {
      print("Error fetching revenue: $e");
    } finally {
      if (mounted) setState(() => _isLoadingRevenue = false);
    }
  }

  void _onFilterChanged(String newFilter) {
    setState(() {
      _selectedFilter = newFilter;
      _cardTitle = 'Pendapatan ${_getFilterTitle(newFilter)}';
    });
    bool isYearly = newFilter == 'tahun_ini';
    _fetchRevenue(_filters[newFilter]!, isYearlyDetail: isYearly);
  }
  
  String _getFilterTitle(String filterKey) {
    switch (filterKey) {
      case 'hari_ini': return 'Hari Ini';
      case 'minggu_ini': return 'Minggu Ini';
      case 'bulan_ini': return 'Bulan Ini';
      case 'tahun_ini': return 'Tahun Ini';
      default: return '';
    }
  }

  Future<void> _fetchIncomingOrdersCount() async {
    if (!mounted) return;
    setState(() {
      _isLoadingIncoming = true;
    });
    const apiUrl = '${ApiConfig.baseUrl}/api/admin/incoming-orders';
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 15));
      if (mounted) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _incomingOrderCount = data['orders'].length;
            _isLoadingIncoming = false;
          });
        } else {
           setState(() => _isLoadingIncoming = false);
        }
      }
    } catch (e) {
      print("Error fetching incoming orders: $e");
      if (mounted) {
        setState(() => _isLoadingIncoming = false);
      }
    }
  }

  Future<void> _fetchOngoingOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoadingOngoing = true;
    });
    const apiUrl = '${ApiConfig.baseUrl}/api/admin/ongoing-orders';
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 15));
       if (mounted) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _ongoingOrders = data['orders'];
            _isLoadingOngoing = false;
          });
        } else {
          setState(() => _isLoadingOngoing = false);
        }
      }
    } catch (e) {
      print("Error fetching ongoing orders: $e");
      if (mounted) {
        setState(() => _isLoadingOngoing = false);
      }
    }
  }

  // --- FUNGSI BARU UNTUK UPDATE STATUS ---
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    final apiUrl = '${ApiConfig.baseUrl}/api/admin/orders/$orderId/next-status';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'newStatus': newStatus}),
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status berhasil diupdate menjadi "$newStatus"')),
          );
          _fetchAdminData(); // Refresh data di halaman utama
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengupdate status.')),
          );
        }
      }
    } catch (e) {
      print("Error updating status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koneksi gagal saat update status.')),
        );
      }
    }
  }

  void _showUpdateStatusSheet(BuildContext context, Map<String, dynamic> order) {
    String currentStatus = order['status'];
    String nextStatus = '';
    String buttonText = '';

    // Logika untuk menentukan status berikutnya
    switch (currentStatus) {
      case 'Cucian Diterima Laundry':
        nextStatus = 'Sedang Dicuci';
        buttonText = 'Ubah ke "Sedang Dicuci"';
        break;
      case 'Sedang Dicuci':
        nextStatus = 'Sedang Dikerjakan';
        buttonText = 'Ubah ke "Sedang Dikerjakan"';
        break;
      case 'Sedang Dikerjakan':
        nextStatus = 'Siap Dikirim/Diambil';
        buttonText = 'Siap Dikirim/Diambil';
        break;
      case 'Siap Dikirim/Diambil':
        nextStatus = 'Selesai';
        buttonText = 'Selesaikan Pesanan';
        break;
      default:
        // Jika status lain atau sudah selesai, tidak ada aksi
        return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Status Pesanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Pesanan: ${order['orderId']}'),
              Text('Status saat ini: $currentStatus'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () {
                    Navigator.pop(ctx); // Tutup bottom sheet
                    _updateOrderStatus(order['orderId'], nextStatus); // Kirim update
                  },
                  child: Text(buttonText, style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchAdminData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 50.0, 24.0, 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileAdminPage(userData: widget.userData),
                              ),
                            );
                          },
                          child: const CircleAvatar(
                            radius: 25,
                            backgroundImage: AssetImage('image/profil.png'),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hallo, Admin', style: TextStyle(fontSize: 16, color: Colors.black54)),
                            Text(widget.userData['namaLengkap'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const Icon(Icons.notifications_none, color: Colors.black54, size: 30),
                  ],
                ),
              ),

              // Ringkasan Hari Ini
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text('Ringkasan Hari Ini', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              _buildSummaryCard(context),
              const SizedBox(height: 30),

              // Proses
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text('Proses', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
                            const SizedBox(height: 10),
              _isLoadingOngoing
                  ? const Center(child: CircularProgressIndicator())
                  : _ongoingOrders.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("Tidak ada pesanan yang sedang diproses.")))
                    : SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          itemCount: _ongoingOrders.length,
                          itemBuilder: (context, index) {
                            final order = _ongoingOrders[index];
                            return _ProcessCard(
                              order: order,
                              adminData: widget.userData,
                              onOrderUpdated: _fetchAdminData,
                              // Menghubungkan tombol dengan fungsi yang kita buat
                              onUpdateStatusPressed: () => _showUpdateStatusSheet(context, order),
                            );
                          },
                        ),
                      ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
                child: Text('Laporan Pendapatan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildMainFilterButtons(),
              ),
              const SizedBox(height: 10),
              _buildRevenueCard(),
              const SizedBox(height: 24),
              if (_selectedFilter == 'tahun_ini')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildMonthlyDetails(),
                ),
              const SizedBox(height: 80), // Ruang untuk FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminComplaintsPage()),
    );
  },
  backgroundColor: const Color(0xFFF06292),
  child: const Icon(Icons.mail_outline, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.home, color: Colors.blue), onPressed: () {}),
            IconButton(icon: const Icon(Icons.history), onPressed: () {Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminHistoryPage(adminData: widget.userData),
            ),
          );}),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF06292),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pesanan Masuk:', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 5),
          _isLoadingIncoming
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  _incomingOrderCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IncomingOrdersPage(onOrderActionCompleted: _fetchAdminData),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFF06292),
              ),
              child: const Text('Rincian'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainFilterButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _filters.keys.map((filterKey) {
          final isSelected = _selectedFilter == filterKey;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onFilterChanged(filterKey),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: isSelected ? Colors.green : Colors.transparent, width: 2),
                ),
                child: Text(
                  _getFilterTitle(filterKey),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRevenueCard() {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF06292),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_cardTitle, style: const TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 5),
          _isLoadingRevenue
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Text(
                  currencyFormatter.format(_totalRevenue),
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                ),
        ],
      ),
    );
  }

  Widget _buildMonthlyDetails() {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final months = ['Januari', 'Febuari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

    return _isLoadingRevenue 
      ? const Center(child: CircularProgressIndicator())
      : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2,
          ),
          itemCount: months.length,
          itemBuilder: (context, index) {
            final monthIndex = index + 1;
            final data = _monthlyRevenue.firstWhere((m) => m['month'] == monthIndex, orElse: () => {'total': 0});
            final total = (data['total']).toDouble();
            
            return Card(
              elevation: 3,
              child: InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(months[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(currencyFormatter.format(total), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
  }
}


 
class _ProcessCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic> adminData;
  final VoidCallback onOrderUpdated;
  final VoidCallback onUpdateStatusPressed;

  const _ProcessCard({
    required this.order,
    required this.adminData,
    required this.onOrderUpdated,
    required this.onUpdateStatusPressed,
  });

  @override
  Widget build(BuildContext context) {
    final user = order['userId'];
    final price = order['price'] ?? 0;

    return GestureDetector(
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
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null)
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage('image/profil.png'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(user['namaLengkap'] ?? '...', style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Harga:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Rp $price', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                Text('Status: ${order['status']}'),
                Text('Layanan: ${order['service']}'),
              ],
            ),

            // --- PERUBAHAN UTAMA: TOMBOL DINAMIS ---
            if (price > 0)
              // Jika harga sudah diinput, tampilkan tombol Update Status
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: onUpdateStatusPressed,
                  icon: const Icon(Icons.update, color: Colors.white, size: 18),
                  label: const Text('Update Status', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(double.infinity, 36),
                  ),
                ),
              )
            else
              // Jika harga masih 0, tampilkan tombol Input Berat
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        final orderId = order['orderId'].toString();
                        return InputWeightPage(
                          orderId: orderId,
                          onOrderUpdated: onOrderUpdated,
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.scale, color: Colors.white, size: 18),
                  label: const Text('Input Berat', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(double.infinity, 36),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}