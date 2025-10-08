import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cleanly/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentSheet extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onPaymentSuccess;

  const PaymentSheet({super.key, required this.order, required this.onPaymentSuccess});

  @override
  _PaymentSheetState createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  int _currentStep = 0;
  String _selectedPaymentMethod = '';
  bool _isProcessingPayment = false;

  Future<void> _confirmPayment() async {
    setState(() => _isProcessingPayment = true);

    final apiUrl = '${ApiConfig.baseUrl}/api/orders/${widget.order['orderId']}/confirm-payment';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'paymentMethod': _selectedPaymentMethod}),
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        if (response.statusCode == 200) {
          Navigator.pop(context); // Tutup bottom sheet
          _showSuccessDialog();    // Tampilkan dialog berhasil
          widget.onPaymentSuccess(); // Panggil callback untuk refresh halaman utama
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengonfirmasi pembayaran.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print("Error confirming payment: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koneksi gagal.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 20),
            Text('Pembayaran Berhasil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Metode pembayaran Anda telah dikonfirmasi.', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double deliveryFee = 0;
    if (widget.order['pickupOption'] == 'Dijemput Kurir') deliveryFee += 5000;
    if (widget.order['deliveryOption'] == 'Diantar Kurir') deliveryFee += 5000;
    final double totalPayment = (widget.order['price'] ?? 0).toDouble();
    final double serviceFee = totalPayment - deliveryFee;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildStepContent(serviceFee, deliveryFee, totalPayment),
        ),
      ),
    );
  }

  Widget _buildStepContent(double serviceFee, double deliveryFee, double totalPayment) {
    switch (_currentStep) {
      case 1:
        return _buildPaymentStep(serviceFee, deliveryFee, totalPayment);
      case 2:
        return _buildConfirmationStep(serviceFee, deliveryFee, totalPayment);
      default: // case 0
        return _buildDetailsStep(serviceFee, deliveryFee, totalPayment);
    }
  }

  Widget _buildDetailsStep(double serviceFee, double deliveryFee, double totalPayment) {
    return Column(
      key: const ValueKey('DetailsStep'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Tagihan Anda', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildStepIndicator(currentIndex: 0),
        const SizedBox(height: 24),
        _buildOrderSummaryCard(),
        const SizedBox(height: 16),
        _buildPaymentDetailsCard(serviceFee, deliveryFee, totalPayment),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent[400],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text('Lanjutkan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep(double serviceFee, double deliveryFee, double totalPayment) {
    return Column(
      key: const ValueKey('PaymentStep'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Tagihan Anda', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildStepIndicator(currentIndex: 1),
        const SizedBox(height: 24),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        _buildPaymentMethodTile(
          icon: Icons.local_shipping_outlined,
          title: 'COD (Cash On Delivery)',
          value: 'COD',
        ),
        const SizedBox(height: 16),
        _buildPaymentDetailsCard(serviceFee, deliveryFee, totalPayment),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _selectedPaymentMethod.isEmpty ? null : () => setState(() => _currentStep = 2),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent[400],
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text('Lanjutkan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep(double serviceFee, double deliveryFee, double totalPayment) {
    return Column(
      key: const ValueKey('ConfirmationStep'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Tagihan Anda', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildStepIndicator(currentIndex: 2),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              _buildDetailRow('Kode Order', widget.order['orderId']),
              _buildDetailRow('Jenis Layanan', widget.order['service']),
              _buildDetailRow('Metode Pembayaran', _selectedPaymentMethod),
              const Divider(height: 24),
              _buildPaymentRow('Biaya Layanan', 'Rp. ${serviceFee.toInt()}'),
              _buildPaymentRow('Jasa antar Pesanan', 'Rp. ${deliveryFee.toInt()}'),
              const Divider(height: 16),
              _buildPaymentRow('Total Pembayaran', 'Rp. ${totalPayment.toInt()}', isTotal: true),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isProcessingPayment ? null : _confirmPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent[400],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: _isProcessingPayment
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text('Bayar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ),
      ],
    );
  }

  // --- WIDGET BANTUAN ---

  Widget _buildPaymentMethodTile({required IconData icon, required String title, required String value}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _selectedPaymentMethod == value ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[700]),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: (val) {
                setState(() {
                  _selectedPaymentMethod = val ?? '';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator({required int currentIndex}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStep(label: 'Rincian\nPesanan', isActive: currentIndex >= 0),
        _buildConnector(isActive: currentIndex >= 1),
        _buildStep(label: 'Pembayaran', isActive: currentIndex >= 1),
        _buildConnector(isActive: currentIndex >= 2),
        _buildStep(label: 'Konfirmasi\nPembayaran', isActive: currentIndex >= 2),
      ],
    );
  }

  Widget _buildStep({required String label, required bool isActive}) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.black : Colors.white,
            border: Border.all(color: isActive ? Colors.black : Colors.grey.shade300, width: 2),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildConnector({bool isActive = false}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.black : Colors.grey[300],
        margin: const EdgeInsets.only(bottom: 28),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SvgPicture.asset('assets/laundry_basket.svg', height: 40, width: 40),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kode Order', style: TextStyle(color: Colors.grey[600])),
                  Text(widget.order['orderId'], style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const Divider(height: 24),
          _buildDetailRow('Jenis Layanan', widget.order['service']),
          _buildDetailRow('Opsi Penjemputan', widget.order['pickupOption']),
          _buildDetailRow('Opsi Pengantaran', widget.order['deliveryOption']),
          _buildDetailRow('Berat Cucian', '${widget.order['weight']} KG'),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard(double serviceFee, double deliveryFee, double totalPayment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rincian Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildPaymentRow('Biaya Layanan', 'Rp. ${serviceFee.toInt()}'),
          _buildPaymentRow('Jasa antar Pesanan', 'Rp. ${deliveryFee.toInt()}'),
          const Divider(height: 16),
          _buildPaymentRow('Total Pembayaran', 'Rp. ${totalPayment.toInt()}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600])),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: isTotal ? Colors.black : Colors.grey[600], fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}