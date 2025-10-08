import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cleanly/pages/login_page.dart';
import 'package:cleanly/config/api_config.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProfilePage({super.key, required this.userData});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _namaLengkapController;
  late final TextEditingController _emailController;
  late final TextEditingController _noTeleponController;
  late final TextEditingController _alamatController;

  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _namaLengkapController = TextEditingController(text: widget.userData['namaLengkap']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _noTeleponController = TextEditingController(text: widget.userData['noTelepon']);
    _alamatController = TextEditingController(text: widget.userData['alamat']);
  }

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _emailController.dispose();
    _noTeleponController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _updateAddress() async {
    final apiUrl = '${ApiConfig.baseUrl}/api/profile/update-address';
    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.userData['email'],
          'alamat': _alamatController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alamat berhasil diperbarui!')),
          );
          setState(() {
            _isEditing = false;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memperbarui alamat.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koneksi gagal.')),
        );
      }
    }
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profil saya', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: Colors.black,
            ),
            onPressed: () {
              if (_isEditing) {
                _updateAddress();
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('image/profil.png'), // Ganti dengan ikon profil Anda
              ),
              const SizedBox(height: 40),
              
              _buildProfileField('Nama Lengkap', _namaLengkapController, false),
              _buildProfileField('Email', _emailController, false),
              _buildProfileField('No Telp.', _noTeleponController, false),
              _buildProfileField('Alamat', _alamatController, _isEditing),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Keluar akun',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileField(String label, TextEditingController controller, bool isEditable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: !isEditable,
          decoration: InputDecoration(
            hintText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            fillColor: isEditable ? Colors.white : Colors.grey[200],
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}