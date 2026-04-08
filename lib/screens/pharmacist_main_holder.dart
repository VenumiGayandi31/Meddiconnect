import 'package:flutter/material.dart';
import 'pharmacist_stock_screen.dart';
import 'pharmacist_orders_screen.dart';
import 'pharmacist_profile_screen.dart';

class PharmacistMainHolder extends StatefulWidget {
  const PharmacistMainHolder({super.key});

  @override
  State<PharmacistMainHolder> createState() => _PharmacistMainHolderState();
}

class _PharmacistMainHolderState extends State<PharmacistMainHolder> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PharmacistStockScreen(),
    const PharmacistOrdersScreen(),
    const PharmacistProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF343A40),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
