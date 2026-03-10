import 'package:flutter/material.dart';
// Sesuaikan import ini dengan nama package project Anda nantinya
import '../../../core/theme/app_theme.dart'; 
import '../../dashboard/screens/dashboard_screen.dart';
import '../../transactions/screens/add_transaction_screen.dart'; 
import '../../transactions/screens/transaction_screen.dart'; 
import '../../budget/screens/budget_screen.dart';
import '../../settings/screens/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Daftar halaman berdasarkan spesifikasi JSON Anda
  final List<Widget> _screens = [
    const DashboardScreen(), 
    const TransactionsScreen(),
    const BudgetScreen(), 
    const SettingsScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      
// import '../../transactions/screens/add_transaction_screen.dart';

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigasi ke AddTransactionScreen saat ditekan
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(icon: Icons.home_outlined, index: 0),
            _buildNavItem(icon: Icons.receipt_long_outlined, index: 1),
            const SizedBox(width: 48), // Ruang kosong untuk FAB di tengah
            _buildNavItem(icon: Icons.bar_chart_outlined, index: 2),
            _buildNavItem(icon: Icons.settings_outlined, index: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index}) {
    final isSelected = _currentIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : Colors.grey,
      ),
      onPressed: () {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }
}