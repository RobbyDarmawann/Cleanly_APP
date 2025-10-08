import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cleanly/config/api_config.dart';

class ComplaintPage extends StatefulWidget {
  final String orderId;

  const ComplaintPage({super.key, required this.orderId});

  @override
  _ComplaintPageState createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final _descriptionController = TextEditingController();
  File? _imageFile;
  final _picker = ImagePicker();
  bool _isSubmitting = false;

  // --- MASUKKAN DETAIL AKUN CLOUDINARY ANDA DI SINI ---
  final String _cloudinaryCloudName = "dlsmpqfba";
  final String _cloudinaryUploadPreset = "cleanly";
  // ----------------------------------------------------

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // FUNGSI INI SEKARANG DIPERBARUI UNTUK MENG-UPLOAD GAMBAR
  Future<void> _submitComplaint() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deskripsi komplain tidak boleh kosong.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    String imageUrl = '';

    // 1. PROSES UPLOAD GAMBAR KE CLOUDINARY (JIKA ADA GAMBAR)
    if (_imageFile != null) {
      try {
        final uploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload');
        final request = http.MultipartRequest('POST', uploadUrl)
          ..fields['upload_preset'] = _cloudinaryUploadPreset
          ..files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));

        final response = await request.send();
        
        if (response.statusCode == 200) {
          final responseData = await response.stream.toBytes();
          final responseString = String.fromCharCodes(responseData);
          final jsonMap = jsonDecode(responseString);
          imageUrl = jsonMap['secure_url']; // Dapatkan URL gambar yang aman
          print('Upload gambar berhasil: $imageUrl');
        } else {
          throw Exception('Gagal upload gambar ke Cloudinary');
        }
      } catch (e) {
        print('Error upload gambar: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengupload gambar.'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isSubmitting = false);
        return;
      }
    }

    final apiUrl = '${ApiConfig.baseUrl}/api/orders/${widget.orderId}/complain';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'description': _descriptionController.text, 'imageUrl': imageUrl}),
      );
      
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Komplain berhasil dikirim.'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengirim komplain ke server.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print('Error kirim komplain: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Komplain Pesanan ${widget.orderId}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Deskripsi Masalah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Jelaskan masalah pada pesanan Anda...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Foto Pesanan (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            
            _imageFile != null
                ? Image.file(_imageFile!)
                : Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                    child: const Icon(Icons.photo_camera_back_outlined, size: 50, color: Colors.grey),
                  ),

            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Pilih Gambar'),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComplaint,
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Kirim Komplain'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}