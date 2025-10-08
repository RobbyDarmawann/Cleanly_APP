import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:cleanly/pages/profile_page.dart';
import 'package:cleanly/pages/user_history_page.dart';
import 'package:cleanly/pages/user_order_details_page.dart';
import 'package:cleanly/pages/payment_sheet.dart';
import 'package:cleanly/pages/notification_page.dart';
import 'package:cleanly/config/api_config.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomePage({super.key, required this.userData});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _ongoingOrders = [];
  bool _isLoading = true;
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  // PERBAIKAN: Fungsi utama untuk mengambil semua data
  Future<void> _fetchAllData() async {
    // Tampilkan loading indicator untuk semua data
    if (mounted) setState(() => _isLoading = true);

    // Panggil kedua fungsi secara bersamaan
    await Future.wait([
      _fetchOrders(),
      _checkNotifications(),
    ]);

    // Hentikan loading setelah semua selesai
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchOrders() async {
    final apiUrl = '${ApiConfig.baseUrl}/api/orders/${widget.userData['_id']}';
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 15));
      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _ongoingOrders = (data['orders'] as List)
              .where((order) => order['status'] != 'Selesai' && order['status'] != 'Ditolak')
              .toList();
        });
      }
    } catch (e) {
      print('Fetch orders error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koneksi Gagal. Periksa jaringan Anda.')),
        );
      }
    }
  }
  
  Future<void> _checkNotifications() async {
    final apiUrl = '${ApiConfig.baseUrl}/api/notifications/${widget.userData['_id']}';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool hasUnread = (data['notifications'] as List).any((notif) => notif['isRead'] == false);
        if (_hasUnreadNotifications != hasUnread) {
          setState(() {
            _hasUnreadNotifications = hasUnread;
          });
        }
      }
    } catch (e) {
      print("Error checking notifications: $e");
    }
  }

  void _showOrderServiceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _OrderServiceSheet(
          userId: widget.userData['_id'],
          onOrderCreated: _fetchAllData, // Gunakan _fetchAllData untuk refresh
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchAllData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              pinned: true,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(userData: widget.userData),
                        ),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('image/profil.png'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hallo,', style: TextStyle(fontSize: 16, color: Colors.black54)),
                      Text(
                        widget.userData['namaLengkap'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.black54, size: 30),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationPage(
                              userId: widget.userData['_id'],
                              onNavigatedBack: _checkNotifications,
                            ),
                          ),
                        );
                        _checkNotifications();
                      },
                    ),
                    if (_hasUnreadNotifications)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
                    child: Text('Layanan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 150,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      children: [
                        _buildServiceCard('image/baju.png', 'Cuci & Lipat'),
                        const SizedBox(width: 15),
                        _buildServiceCard('image/mesincuci.png', 'Cuci & Setrika'),
                        const SizedBox(width: 15),
                        _buildServiceCard('image/kainse.png', 'Setrika saja'),
                        const SizedBox(width: 15),
                        _buildServiceCard('image/fast.png', 'One Day Service'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text('Tentang Kami', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 200,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      children: [
                         _AboutCard(
                          title: 'Alamat:',
                          subtitle: 'Jl. Beringin No. 123, Gorontalo',
                          imagePath: 'image/map.png',
                          cardColor: const Color(0xFFF06292),
                        ),
                        const SizedBox(width: 15),
                        _AboutCard(
                          title: 'Jam Operasional:',
                          subtitle: '08:00 - 20:00',
                          imagePath: 'image/jam.png',
                          cardColor: Colors.green,
                        ),
                        const SizedBox(width: 15),
                        _AboutCard(
                          title: 'Nomor Telepon:',
                          subtitle: '+62895805096640',
                          imagePath: 'image/telepon.png',
                          cardColor: Colors.orange,
                        ),
                        const SizedBox(width: 15),
                        _AboutCard(
                          title: 'Harga:',
                          subtitle: 'Mulai dari 5000 Rupiah saja',
                          imagePath: 'image/telepon.png',
                          cardColor: const Color.fromARGB(255, 42, 79, 201),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text('Sedang Berlangsung', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 15),
                  _isLoading
                      ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                      : _ongoingOrders.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Tidak ada pesanan aktif saat ini.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                              ),
                            )
                          : ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: _ongoingOrders.length,
                              itemBuilder: (context, index) {
                                final order = _ongoingOrders[index];
                                return _OngoingOrderCard(
                                  order: order,
                                  userData: widget.userData,
                                );
                              },
                            ),
                   const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _showOrderServiceSheet,
        backgroundColor: Colors.pink[300],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.home, color: Colors.blue), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserHistoryPage(userId: widget.userData['_id'])),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(String imagePath, String serviceName) {
    return Column(
      children: [
        GestureDetector(
          onTap: _showOrderServiceSheet,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(imagePath, width: 60, height: 60),
          ),
        ),
        const SizedBox(height: 8),
        Text(serviceName),
      ],
    );
  }
}

class _OngoingOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic> userData;

  const _OngoingOrderCard({required this.order, required this.userData});

  @override
  Widget build(BuildContext context) {
    final orderId = order['orderId'].toString();
    final service = order['service'] as String;
    final date = order['orderDate'] as String;
    final status = order['status'] as String;
    final price = (order['price'] ?? 0).toDouble();
    final paymentStatus = order['paymentStatus'] as String? ?? 'Belum Dibayar';
    final orderDateTime = DateTime.parse(date);
    final formattedDate = DateFormat('d MMM yyyy', 'id_ID').format(orderDateTime);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserOrderDetailsPage(orderData: order),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        elevation: 2.0,
        shadowColor: Colors.grey.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Center(
                  child: SvgPicture.asset('assets/laundry_basket.svg', height: 35, width: 35),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order $orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
                    const SizedBox(height: 4.0),
                    Text(service, style: TextStyle(fontSize: 14.0, color: Colors.grey[600])),
                    const SizedBox(height: 4.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status, style: TextStyle(fontSize: 12.0, color: Colors.blue[800], fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Rp. ${price.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  const SizedBox(height: 8.0),
                  if (price > 0 && paymentStatus == 'Belum Dibayar')
                    ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => PaymentSheet(
                            order: order,
                            onPaymentSuccess: () {
                              context.findAncestorStateOfType<_HomePageState>()?. _fetchAllData();
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Bayar Tagihan', style: TextStyle(color: Colors.white, fontSize: 12)),
                    )
                  else
                    Text(formattedDate, style: TextStyle(fontSize: 12.0, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderServiceSheet extends StatefulWidget {
  final String userId;
  final VoidCallback onOrderCreated;

  const _OrderServiceSheet({required this.userId, required this.onOrderCreated});

  @override
  _OrderServiceSheetState createState() => _OrderServiceSheetState();
}

class _OrderServiceSheetState extends State<_OrderServiceSheet> {
  String? _selectedService;
  String? _selectedPickupOption;
  String? _selectedDeliveryOption;
  bool _isCreatingOrder = false;

  Future<void> _createOrder() async {
    if (_selectedService == null || _selectedPickupOption == null || _selectedDeliveryOption == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap lengkapi semua pilihan layanan.')),
        );
      }
      return;
    }

    setState(() => _isCreatingOrder = true);

    const apiUrl = '${ApiConfig.baseUrl}/api/order';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'service': _selectedService,
          'pickupOption': _selectedPickupOption,
          'deliveryOption': _selectedDeliveryOption,
        }),
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        if (response.statusCode == 201) {
          Navigator.pop(context);
          _showSuccessDialog();
          widget.onOrderCreated();
        } else {
          final errorData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: ${errorData['message'] ?? 'Terjadi kesalahan server'}')),
          );
        }
      }
    } catch (e) {
      print('Terjadi kesalahan saat membuat pesanan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koneksi Gagal. Periksa jaringan Anda.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingOrder = false);
    }
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
              SizedBox(height: 20),
              Text('Pesanan Berhasil Dibuat', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('Silakan tunggu konfirmasi dari admin.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pesan Layanan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Jenis Layanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildOptionButtons(
                ['Cuci & Lipat', 'Cuci & Setrika', 'Setrika saja', 'One Day Service'],
                _selectedService,
                (value) => setState(() => _selectedService = value),
              ),
              const SizedBox(height: 20),
              const Text('Opsi Penjemputan (Kain Kotor)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildOptionButtons(
                ['Dijemput Kurir', 'Antar Sendiri'],
                _selectedPickupOption,
                (value) => setState(() => _selectedPickupOption = value),
              ),
              const SizedBox(height: 20),
              const Text('Opsi Pengantaran (Cucian Bersih)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildOptionButtons(
                ['Diantar Kurir', 'Ambil Sendiri'],
                _selectedDeliveryOption,
                (value) => setState(() => _selectedDeliveryOption = value),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isCreatingOrder ? null : _createOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isCreatingOrder
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Pesan Sekarang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButtons(List<String> options, String? selectedValue, ValueChanged<String?> onChanged) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = option == selectedValue;
        return ElevatedButton(
          onPressed: () => onChanged(option),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.white,
            foregroundColor: isSelected ? Colors.white : Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(color: isSelected ? Colors.blue : Colors.grey.shade300),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(option),
        );
      }).toList(),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final Color cardColor;

  const _AboutCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 375,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(imagePath, height: 80, fit: BoxFit.contain),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}