import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'homepage.dart';
import 'inventory.dart';
import 'profile.dart';
import 'UserSession.dart';
import 'reportanalytics.dart';
import 'providers/theme_provider.dart';

const Color deepIndigo = Color(0xFF211C84);
const Color brightBlue = Color(0xFF0037FF);
const Color darkShade1 = Color.fromARGB(255, 24, 28, 20);
const Color darkShade2 = Color.fromARGB(255, 60, 61, 55);
const Color darkShade3 = Color.fromARGB(255, 105, 117, 101);

Widget buildHeader(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final bool isDark = themeProvider.isDarkMode;

  return SafeArea(
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      decoration: BoxDecoration(
        color: isDark ? darkShade1 : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white30 : Colors.black26,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 150,
            color: isDark ? Colors.white : null,
            colorBlendMode: BlendMode.srcIn,
          ),
          Text(
            UserSession().companyName ?? '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : deepIndigo,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget BottomNav(BuildContext context, int? currentIndex) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final bool isDark = themeProvider.isDarkMode;

  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    currentIndex: currentIndex != null && currentIndex >= 0 ? currentIndex : 0,
    backgroundColor: isDark ? darkShade1 : Colors.white,
    selectedItemColor: (currentIndex != null && currentIndex >= 0)
        ? (isDark ? Colors.white : brightBlue)
        : (isDark ? darkShade3 : deepIndigo),
    unselectedItemColor: isDark ? darkShade3 : deepIndigo,
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
