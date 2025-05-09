import 'package:flutter/material.dart';
import 'homepage.dart';
import 'inventory.dart';
import 'profile.dart';
import 'UserSession.dart';
import 'reportanalytics.dart';

const Color deepIndigo = Color(0xFF211C84);
const Color brightBlue = Color(0xFF0037FF);

// Header Widget
Widget buildHeader() {
  return SafeArea(
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black26, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/logo.png', width: 150),
          Text(
            UserSession().companyName ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: deepIndigo,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget BottomNav(BuildContext context, int? currentIndex) {
  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    currentIndex: currentIndex != null && currentIndex >= 0 ? currentIndex : 0,
    backgroundColor: Colors.white,
    selectedItemColor:
        currentIndex != null && currentIndex >= 0 ? brightBlue : deepIndigo,
    unselectedItemColor: deepIndigo,
    onTap: (index) {
      if (index == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else if (index == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const InventoryPage()),
        );
      } else if (index == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ReportAnalyticsPage()),
        );
      } else if (index == 3) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
      }
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Inventory'),
      BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart), label: 'Report & Analytics'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ],
  );
}
