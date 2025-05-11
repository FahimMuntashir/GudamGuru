import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'UserSession.dart';
import 'header&nav.dart';
import 'login.dart';
import 'providers/theme_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String selectedLanguage = 'English';
  final List<String> languages = ['English', 'Bangla'];

  void _showChangePasswordDialog(BuildContext context) {
    TextEditingController oldPass = TextEditingController();
    TextEditingController newPass = TextEditingController();
    TextEditingController confirmPass = TextEditingController();

    bool _obscureOld = true;
    bool _obscureNew = true;
    bool _obscureConfirm = true;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPass,
                    obscureText: _obscureOld,
                    decoration: InputDecoration(
                      labelText: 'Old Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureOld
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscureOld = !_obscureOld;
                          });
                        },
                      ),
                    ),
                  ),
                  TextField(
                    controller: newPass,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscureNew = !_obscureNew;
                          });
                        },
                      ),
                    ),
                  ),
                  TextField(
                    controller: confirmPass,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                TextButton(
                  child: const Text('Change'),
                  onPressed: () async {
                    if (newPass.text != confirmPass.text) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Passwords do not match.')),
                      );
                      return;
                    }

                    var url = Uri.parse(
                        'http://192.168.0.10/gudamguru_api/change_password.php');
                    var response = await http.post(url, body: {
                      'user_id': UserSession().userId,
                      'old_password': oldPass.text,
                      'new_password': newPass.text,
                    });

                    var data = json.decode(response.body);
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(data['message'])),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
              'Are you sure you want to permanently delete this account?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Proceed'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showOtpDialog(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showOtpDialog(BuildContext context) {
    TextEditingController otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Enter OTP'),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter OTP sent to your phone',
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                String enteredOtp = otpController.text.trim();

                if (enteredOtp == '111111') {
                  // Proceed to delete account
                  var url = Uri.parse(
                      'http://192.168.0.10/gudamguru_api/delete_account.php');
                  var response = await http.post(url, body: {
                    'user_id': UserSession().userId,
                  });

                  var data = json.decode(response.body);
                  if (data['status'] == 'success') {
                    UserSession().clear();
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(data['message'])),
                    );
                  }
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid OTP')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                UserSession().clear(); // Clear session
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/background.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        buildHeader(context),
                        const SizedBox(height: 20),

                        // User Information
                        _buildSectionTitle('User Information'),
                        _buildUserInfo(),

                        // Account & Settings
                        _buildSectionTitle('Account & Settings'),
                        _buildAccountSettings(),

                        // Permissions & Security
                        _buildSectionTitle('Permissions & Security'),
                        _buildSecuritySettings(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: BottomNav(context, 3));
  }

  Widget _buildUserInfo() {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(
                "User Name: ${UserSession().userId}",
                style: TextStyle(
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black),
              ),
            ),
            ListTile(
              title: Text(
                "Contact Number: ${UserSession().phone}",
                style: TextStyle(
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black),
              ),
            ),
            ListTile(
              title: Text(
                "Company Name: ${UserSession().companyName}",
                style: TextStyle(
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black),
              ),
            ),
            ListTile(
              title: Text(
                "Company ID: ${UserSession().companyId}",
                style: TextStyle(
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black),
              ),
            ),
            Divider(
                color:
                    themeProvider.isDarkMode ? Colors.white70 : Colors.black),
            ListTile(
              title: Text(
                'Change Password',
                style: TextStyle(
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.lock),
                onPressed: () => _showChangePasswordDialog(context),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings() {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(
                'Language Selection',
                style: TextStyle(
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black),
              ),
              trailing: DropdownButton<String>(
                value: selectedLanguage,
                items: languages.map((String language) {
                  return DropdownMenuItem<String>(
                    value: language,
                    child: Text(
                      language,
                      style: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedLanguage = newValue!;
                  });
                },
              ),
            ),
            SwitchListTile(
              title: Text(
                'Dark Mode',
                style: TextStyle(
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black),
              ),
              value: themeProvider.isDarkMode,
              onChanged: (bool value) {
                themeProvider.toggleTheme();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettings() {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(
                'Logout',
                style: TextStyle(
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.exit_to_app),
                onPressed: () => _confirmLogout(context),
              ),
            ),
            // Divider(
            //     color:
            //         themeProvider.isDarkMode ? Colors.white70 : Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
