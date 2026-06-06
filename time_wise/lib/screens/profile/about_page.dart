import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Tentang Aplikasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20), 
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF2EAD65),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2EAD65).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ]
                ),
                child: const Icon(Icons.hourglass_top_rounded, size: 45, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'TimeWise',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
              const Text(
                'Versi 1.0.0',
                style: TextStyle(fontSize: 13, color: Colors.black38, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration( 
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'TimeWise adalah aplikasi manajemen waktu cerdas yang dirancang untuk membantu penggunanya dengan profesional dan mengatur jadwal harian, mengelola tugas, serta melacak tingkat produktivitas agar hari-harimu menjadi lebih terstruktur.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.6),
                ),
              ),
              const Spacer(),
              const Text(
                'Dibuat dengan penuh ❤️ oleh Tim TimeWise',
                style: TextStyle(fontSize: 12, color: Colors.black38),
              ),
              const SizedBox(height: 8),
              const Text(
                '© 2026 TimeWise. All rights reserved.',
                style: TextStyle(fontSize: 11, color: Colors.black26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}