import 'package:flutter/material.dart';
import 'pharmacist_stock_screen.dart';
import 'pharmacist_orders_screen.dart';
import 'pharmacist_profile_screen.dart';

// OOP Concepts Used:
// - Encapsulation: Private variables like _currentIndex and _pages are managed داخل class
// - Inheritance: Extends StatefulWidget to create a dynamic UI component
// - Abstraction: Navigation logic is separated and hidden inside this class
// - Polymorphism: Method overriding (createState and build)

class PharmacistMainHolder extends StatefulWidget {
  const PharmacistMainHolder({super.key});

  @override
  // Creates and returns the state object for this widget
  State<PharmacistMainHolder> createState() => _PharmacistMainHolderState();
}

// OOP Concepts Used:
// - Encapsulation: Maintains internal state (_currentIndex)
// - Inheritance: Extends State class
// - Abstraction: UI rendering and navigation handled inside methods
class _PharmacistMainHolderState extends State<PharmacistMainHolder> {

  // Stores the currently selected index of the bottom navigation bar
  int _currentIndex = 0;

  // Stores the list of pages/screens displayed in the IndexedStack
  final List<Widget> _pages = [
    const PharmacistStockScreen(),
    const PharmacistOrdersScreen(),
    const PharmacistProfileScreen(),
  ];

  @override
  // Builds the main UI including bottom navigation and page switching
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
