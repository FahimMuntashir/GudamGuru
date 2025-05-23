// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'header&nav.dart';
import 'UserSession.dart';
import 'login.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'homepage.dart';
import 'database_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

// import 'package:permission_handler/permission_handler.dart';

const Color deepIndigo = Color(0xFF211C84);
const Color vibrantBlue = Color(0xFF4D55CC);
const Color brightBlue = Color(0xFF0037FF);
const Color darkShade1 = Color.fromARGB(255, 24, 28, 20);
const Color darkShade2 = Color.fromARGB(255, 60, 61, 55);
const Color darkShade3 = Color.fromARGB(255, 105, 117, 101);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String selectedLanguage = 'English';
  final List<Map<String, String>> languages = [
    {'key': 'English', 'label': 'English'},
    {'key': 'Bangla', 'label': 'বাংলা'},
  ];

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
        final themeProvider = Provider.of<ThemeProvider>(dialogContext);
        final languageProvider = Provider.of<LanguageProvider>(dialogContext);
        final bool isDark = themeProvider.isDarkMode;
        final bool isBangla = languageProvider.isBangla;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? darkShade1 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                isBangla ? 'পাসওয়ার্ড পরিবর্তন' : 'Change Password',
                style: themedBoldTextStyle(
                  isDark: isDark,
                  weight: FontWeight.w700,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPasswordField(
                    isDark: isDark,
                    controller: oldPass,
                    label: isBangla ? 'পুরাতন পাসওয়ার্ড' : 'Old Password',
                    obscureText: _obscureOld,
                    toggleVisibility: () =>
                        setState(() => _obscureOld = !_obscureOld),
                  ),
                  _buildPasswordField(
                    isDark: isDark,
                    controller: newPass,
                    label: isBangla ? 'নতুন পাসওয়ার্ড' : 'New Password',
                    obscureText: _obscureNew,
                    toggleVisibility: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                  _buildPasswordField(
                    isDark: isDark,
                    controller: confirmPass,
                    label: isBangla
                        ? 'নতুন পাসওয়ার্ড নিশ্চিত করুন'
                        : 'Confirm New Password',
                    obscureText: _obscureConfirm,
                    toggleVisibility: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text(
                    isBangla ? 'বাতিল' : 'Cancel',
                    style: themedBoldTextStyle(
                      isDark: isDark,
                      weight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? darkShade3 : brightBlue,
                  ),
                  child: Text(
                    isBangla ? 'পরিবর্তন করুন' : 'Change',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    if (newPass.text != confirmPass.text) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isBangla
                                ? 'পাসওয়ার্ড মিলছে না।'
                                : 'Passwords do not match.',
                          ),
                          backgroundColor: isDark ? darkShade3 : deepIndigo,
                        ),
                      );
                      return;
                    }

                    var url = Uri.parse(
                        'http://192.168.0.179/gudamguru_api/change_password.php');
                    var response = await http.post(url, body: {
                      'user_id': UserSession().userId,
                      'old_password': oldPass.text,
                      'new_password': newPass.text,
                    });

                    var data = json.decode(response.body);
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(data['message']),
                        backgroundColor: isDark ? darkShade3 : deepIndigo,
                      ),
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

  Widget _buildPasswordField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback toggleVisibility,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: themedBoldTextStyle(isDark: isDark),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: isDark ? Colors.white70 : deepIndigo,
          ),
          filled: true,
          fillColor: isDark ? darkShade2 : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: isDark ? darkShade3 : deepIndigo, width: 1.5),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: isDark ? Colors.white : deepIndigo,
            ),
            onPressed: toggleVisibility,
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final themeProvider = Provider.of<ThemeProvider>(dialogContext);
        final languageProvider = Provider.of<LanguageProvider>(dialogContext);
        final bool isDark = themeProvider.isDarkMode;
        final bool isBangla = languageProvider.isBangla;

        return AlertDialog(
          backgroundColor: isDark ? darkShade1 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            isBangla ? 'লগআউট নিশ্চিত করুন' : 'Confirm Logout',
            style: themedBoldTextStyle(
              isDark: isDark,
              weight: FontWeight.w700,
            ),
          ),
          content: Text(
            isBangla
                ? 'আপনি কি নিশ্চিতভাবে লগআউট করতে চান?'
                : 'Are you sure you want to logout?',
            style: themedBoldTextStyle(
              isDark: isDark,
              weight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                isBangla ? 'বাতিল' : 'Cancel',
                style: themedBoldTextStyle(
                  isDark: isDark,
                  weight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? darkShade3 : brightBlue,
              ),
              child: Text(
                isBangla ? 'লগআউট' : 'Logout',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await UserSession().clear();
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

  Future<void> exportDatabaseToDownloads() async {
    try {
      final dbPath =
          '${(await getApplicationDocumentsDirectory()).path}/gudamguru.db';
      final originalDb = File(dbPath);

      if (!await originalDb.exists()) {
        print('Database file not found');
        return;
      }

      final rawName = UserSession().companyName ?? 'backup';
      final sanitizedName = rawName
          .trim()
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_');
      final filename = '${sanitizedName.toLowerCase()}.db';

      //Copy to a temp file with the new name
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$filename';
      final tempFile =
          await File(tempPath).writeAsBytes(await originalDb.readAsBytes());

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: '$rawName database backup',
      );

      print('Shared database: $tempPath');
    } catch (e) {
      print('Error sharing database: $e');
    }
  }

  Future<void> importDatabaseFromUser() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) {
        print('No file selected.');
        return;
      }

      final selectedPath = result.files.single.path!;
      final selectedFile = File(selectedPath);

      // Check extension manually
      if (!selectedPath.toLowerCase().endsWith('.db')) {
        print('The selected file is not a .db file.');
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final newPath = '${appDir.path}/gudamguru.db';
      await selectedFile.copy(newPath);
      print('Imported DB to: $newPath');
    } catch (e) {
      print('Error importing database: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    return Scaffold(
        backgroundColor: isDark
            ? const Color.fromARGB(240, 0, 0, 0)
            : const Color.fromARGB(240, 255, 255, 255),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/background.png'),
                    opacity: 0.1,
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
                        _buildSectionTitle(isBangla
                            ? 'ব্যবহারকারীর তথ্য'
                            : 'User Information'),
                        _buildUserInfo(),
                        const SizedBox(height: 10),

                        // Account & Settings
                        _buildSectionTitle(isBangla ? 'সেটিংস' : 'Settings'),
                        _buildAccountSettings(),
                        const SizedBox(height: 10),

                        // Permissions & Security
                        _buildSectionTitle(isBangla
                            ? 'অনুমতি ও নিরাপত্তা'
                            : 'Permissions & Security'),
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
        bottomNavigationBar: bottomNav(context, 3));
  }

  Widget _buildUserInfo() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? darkShade1 : vibrantBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: isDark ? darkShade3 : deepIndigo,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(
                isBangla
                    ? "ব্যবহারকারীর নাম: ${UserSession().userId}"
                    : "User Name: ${UserSession().userId}",
                style: themedBoldTextStyle(
                  isDark: isDark,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              title: Text(
                isBangla
                    ? "মোবাইল নাম্বার: ${UserSession().phone}"
                    : "Contact Number: ${UserSession().phone}",
                style: themedBoldTextStyle(
                  isDark: isDark,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              title: Text(
                isBangla
                    ? "প্রতিষ্ঠানের নাম: ${UserSession().companyName}"
                    : "Company Name: ${UserSession().companyName}",
                style: themedBoldTextStyle(
                  isDark: isDark,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              title: Text(
                isBangla
                    ? "প্রতিষ্ঠান আইডি: ${UserSession().companyId}"
                    : "Company ID: ${UserSession().companyId}",
                style: themedBoldTextStyle(
                  isDark: isDark,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            Divider(
              color: isDark ? Colors.white70 : deepIndigo,
              thickness: 1,
            ),
            ListTile(
              title: Text(
                isBangla ? 'পাসওয়ার্ড পরিবর্তন করুন' : 'Change Password',
                style: themedBoldTextStyle(
                  isDark: isDark,
                  weight: FontWeight.w800,
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.lock,
                  color: isDark ? Colors.white : deepIndigo,
                ),
                onPressed: () => _showChangePasswordDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings() {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? darkShade1 : vibrantBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: isDark ? darkShade3 : deepIndigo,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(
                isBangla ? 'ভাষা নির্বাচন' : 'Language Selection',
                style: themedBoldTextStyle(
                  isDark: isDark,
                  weight: FontWeight.w600,
                ),
              ),
              trailing: DropdownButton<String>(
                value: isBangla ? 'Bangla' : 'English',
                dropdownColor: isDark ? darkShade1 : Colors.white,
                items: languages.map((lang) {
                  return DropdownMenuItem<String>(
                    value: lang['key'],
                    child: Text(
                      lang['label']!,
                      style: themedBoldTextStyle(
                        isDark: isDark,
                        weight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    languageProvider.setLanguage(newValue == 'Bangla');
                  }
                },
                iconEnabledColor: isDark ? Colors.white : deepIndigo,
              ),
            ),
            SwitchListTile(
              title: Text(
                isBangla ? 'ডার্ক মোড' : 'Dark Mode',
                style: themedBoldTextStyle(
                  isDark: isDark,
                  weight: FontWeight.w600,
                ),
              ),
              value: isDark,
              onChanged: (bool value) {
                themeProvider.toggleTheme();
              },
              activeColor: isDark ? Colors.white : brightBlue,
              activeTrackColor: vibrantBlue.withOpacity(0.6),
              inactiveThumbColor: isDark ? darkShade3 : deepIndigo,
              inactiveTrackColor:
                  isDark ? Colors.white : deepIndigo.withOpacity(0.3),
            ),
            ListTile(
              title: Text(
                isBangla ? 'ডাটাবেজ ডাউনলোড' : 'Download Database',
                style: themedBoldTextStyle(
                  isDark: isDark,
                  weight: FontWeight.w600,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.download_rounded),
                color: isDark ? Colors.white : deepIndigo,
                tooltip: isBangla ? 'ডাটাবেজ রপ্তানি করুন' : 'Export database',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: isDark ? darkShade1 : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          isBangla
                              ? 'ডাউনলোড নিশ্চিত করুন'
                              : 'Confirm Download',
                          style: themedBoldTextStyle(
                            isDark: isDark,
                            weight: FontWeight.w700,
                          ),
                        ),
                        content: Text(
                          isBangla
                              ? 'আপনি কি ডাটাবেজ ব্যাকআপ ডাউনলোড করতে চান?'
                              : 'Do you want to download a backup of the database?',
                          style: themedBoldTextStyle(
                            isDark: isDark,
                            weight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: Text(
                              isBangla ? 'বাতিল' : 'Cancel',
                              style: themedBoldTextStyle(
                                isDark: isDark,
                                weight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? darkShade3 : brightBlue,
                            ),
                            child: Text(
                              isBangla ? 'ডাউনলোড' : 'Download',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () async {
                              Navigator.of(context).pop(); // close dialog
                              await exportDatabaseToDownloads(); // perform export

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isBangla
                                          ? 'ডাটাবেজ সফলভাবে ডাউনলোড হয়েছে!'
                                          : 'Database downloaded successfully!',
                                    ),
                                    backgroundColor:
                                        isDark ? darkShade3 : deepIndigo,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettings() {
    final themeProvider = context.watch<ThemeProvider>();
    final bool isDark = themeProvider.isDarkMode;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isBangla = languageProvider.isBangla;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? darkShade1 : vibrantBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: isDark ? darkShade3 : deepIndigo,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(
                isBangla ? 'লগআউট' : 'Logout',
                style: themedBoldTextStyle(
                  isDark: isDark,
                  weight: FontWeight.w600,
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.exit_to_app,
                  color: isDark ? Colors.white : deepIndigo,
                ),
                onPressed: () => _confirmLogout(context),
                tooltip: isBangla ? 'লগআউট করুন' : 'Logout',
              ),
            ),
            ListTile(
              title: Text(
                isBangla ? 'ডাটাবেজ আপলোড করুন' : 'Upload Database',
                style: themedBoldTextStyle(
                  isDark: isDark,
                  weight: FontWeight.w600,
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.upload_file,
                  color: isDark ? Colors.white : deepIndigo,
                ),
                tooltip: isBangla
                    ? 'আপনার ডাটাবেজ আপলোড করুন'
                    : 'Upload your database',
                onPressed: () {
                  final outerContext = context;

                  showDialog(
                    context: outerContext,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: isDark ? darkShade1 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        isBangla ? 'আপলোড নিশ্চিত করুন' : 'Confirm Upload',
                        style: themedBoldTextStyle(
                          isDark: isDark,
                          weight: FontWeight.w700,
                        ),
                      ),
                      content: Text(
                        isBangla
                            ? 'এই অপারেশন আপনার বর্তমান ডাটাবেজটি প্রতিস্থাপন করবে। আপনি কি নিশ্চিত?'
                            : 'This will replace your current database. Are you sure?',
                        style: themedBoldTextStyle(
                          isDark: isDark,
                          weight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: Text(
                            isBangla ? 'বাতিল' : 'Cancel',
                            style: themedBoldTextStyle(
                              isDark: isDark,
                              weight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? darkShade3 : brightBlue,
                          ),
                          child: Text(
                            isBangla ? 'আপলোড' : 'Upload',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            await importDatabaseFromUser();
                            DatabaseHelper().resetDatabaseConnection();

                            if (!mounted) return;
                            Navigator.pushAndRemoveUntil(
                              outerContext,
                              MaterialPageRoute(
                                  builder: (context) => const HomePage()),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : deepIndigo,
        ),
      ),
    );
  }

  TextStyle themedBoldTextStyle({
    required bool isDark,
    double fontSize = 16,
    FontWeight weight = FontWeight.bold,
  }) {
    return TextStyle(
      color: isDark ? Colors.white : deepIndigo,
      fontWeight: weight,
      fontSize: fontSize,
    );
  }
}
