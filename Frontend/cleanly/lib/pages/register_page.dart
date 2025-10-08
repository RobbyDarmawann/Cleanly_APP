import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cleanly/pages/login_page.dart'; 
import 'package:cleanly/config/api_config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _namaLengkapController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noTeleponController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _kataSandiController = TextEditingController();

  // Alamat IP lokal atau 10.0.2.2 untuk emulator Android
  final String _apiUrl = '${ApiConfig.baseUrl}/api/register';

  Future<void> _register() async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'namaLengkap': _namaLengkapController.text,
        'email': _emailController.text,
        'noTelepon': _noTeleponController.text,
        'alamat': _alamatController.text,
        'kataSandi': _kataSandiController.text,
      }),
    );

    if (response.statusCode == 201) {
      // Registrasi berhasil
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil!')),
        );
        // Navigasi ke halaman login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } else {
      // Registrasi gagal
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi gagal. Silakan coba lagi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header dengan background biru dan logo
            Container(
              width: double.infinity,
              height: 250,
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: SvgPicture.asset(
                      'assets/cleanly_logo.svg',
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Text(
                      'Daftar Akun',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Konten form daftar
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // Input Nama Lengkap
                  TextField(
                    controller: _namaLengkapController,
                    decoration: InputDecoration(
                      hintText: 'Nama Lengkap Anda',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Input Email
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Email Anda',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Input No Telepon
                  TextField(
                    controller: _noTeleponController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Nomor Telepon Anda',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Input Alamat
                  TextField(
                    controller: _alamatController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Alamat Anda',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Input Kata Sandi
                  TextField(
                    controller: _kataSandiController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Kata Sandi Anda',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Tombol Daftar Sekarang
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF06292),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Daftar Sekarang',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Teks "Sudah punya akun? Masuk Sekarang"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun?',
                        style: TextStyle(color: Colors.black54),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: const Text(
                          'Masuk Sekarang',
                          style: TextStyle(
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}