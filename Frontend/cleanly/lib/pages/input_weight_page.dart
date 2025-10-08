import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cleanly/config/api_config.dart';
import 'dart:convert';

class InputWeightPage extends StatefulWidget {
  final String orderId;
  final VoidCallback onOrderUpdated;

  const InputWeightPage({super.key, required this.orderId, required this.onOrderUpdated});

  @override
  _InputWeightPageState createState() => _InputWeightPageState();
}

class _InputWeightPageState extends State<InputWeightPage> {
  final TextEditingController _weightController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updateOrderPrice() async {
    if (_weightController.text.isEmpty || double.tryParse(_weightController.text) == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan berat yang valid.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final apiUrl = '${ApiConfig.baseUrl}/api/admin/orders/${widget.orderId}/update-price';
    print('Mengirim update harga untuk Order ID: ${widget.orderId}');
    print('Berat yang dikirim: ${_weightController.text}');

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'weight': double.parse(_weightController.text)}),
      ).timeout(const Duration(seconds: 15)); 

      if (!mounted) return;

      print('Respons server: ${response.statusCode}');
      print('Body respons: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berat dan harga berhasil diperbarui!')),
        );
        Navigator.pop(context);
        widget.onOrderUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui berat dan harga.')),
        );
      }
    } catch (e) {
      // <-- PERBAIKAN 3: Menambah print error untuk mempermudah debug
      print('Error updating price: $e'); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koneksi Gagal. Periksa jaringan Anda.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Berat Cucian',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: 'KG',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateOrderPrice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Konfirmasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}