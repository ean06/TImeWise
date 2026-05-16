import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5EE09A), Color(0xFF2EAD65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Avatar
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Username',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pengguna TimeWise',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),

              const SizedBox(height: 28),

              // Menu list
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        label: 'Edit Profile',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: Icons.lock_outline,
                        label: 'Ubah Password',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notifikasi',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        label: 'Tentang Aplikasi',
                        onTap: () {},
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        icon: Icons.logout,
                        label: 'Keluar',
                        color: Colors.redAccent,
                        onTap: () {
                          Navigator.pushReplacementNamed(
                              context, '/LoginPage');
                        },
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

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? const Color(0xFF2EAD65), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color ?? Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color ?? Colors.black26,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}