// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'UserSession.dart';
import 'homepage.dart';

const Color deepIndigo = Color(0xFF211C84);
const Color vibrantBlue = Color(0xFF4D55CC);
const Color brightBlue = Color(0xFF0037FF);
const Color darkShade1 = Color.fromARGB(255, 24, 28, 20);
const Color darkShade2 = Color.fromARGB(255, 60, 61, 55);
const Color darkShade3 = Color.fromARGB(255, 105, 117, 101);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> loginUser() async {
    var url = Uri.parse('http://192.168.0.179/gudamguru_api/login.php');

    var response = await http.post(url, body: {
      'user_id': userIdController.text,
      'password': passwordController.text,
    });

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    var data = json.decode(response.body);

    if (data['status'] == 'success') {
      final session = UserSession();
      session.companyId = data['data']['id'];
      session.userId = data['data']['user_id'];
      session.companyName = data['data']['company_name'];
      session.phone = data['data']['phone'];
      await session.saveToPrefs();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color.fromARGB(240, 0, 0, 0)
          : const Color.fromARGB(240, 255, 255, 255),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.1),
            ),
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 200,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _buildTextField(context, userIdController, 'User Name'),
                    _buildTextField(context, passwordController, 'Password',
                        isPassword: true),
                    _buildButton(context, 'Login', loginUser),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildTextField(
    BuildContext context, TextEditingController controller, String hint,
    {bool isPassword = false}) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final bool isDark = themeProvider.isDarkMode;

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white : deepIndigo,
        ),
        filled: true,
        fillColor: isDark ? darkShade1 : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: isDark ? darkShade2 : deepIndigo, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: isDark ? darkShade2 : deepIndigo, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color:
                  isDark ? darkShade3 : const Color.fromARGB(255, 13, 0, 255),
              width: 2),
        ),
      ),
    ),
  );
}

Widget _buildButton(BuildContext context, String text, VoidCallback onPressed) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final bool isDark = themeProvider.isDarkMode;

  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: isDark ? darkShade1 : brightBlue,
      side: BorderSide(color: isDark ? darkShade3 : deepIndigo, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    onPressed: onPressed,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
