import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login.dart';
import 'homepage.dart';
import 'providers/theme_provider.dart';
import 'signUpPage.dart';
import 'providers/language_provider.dart';
import 'UserSession.dart';

const Color deepIndigo = Color(0xFF211C84);
const Color brightBlue = Color(0xFF0037FF);
const Color darkShade1 = Color.fromARGB(255, 24, 28, 20);
const Color darkShade3 = Color.fromARGB(255, 105, 117, 101);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = UserSession();
  await session.loadFromPrefs();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MyApp(isLoggedIn: session.isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.green,
            useMaterial3: true,
            brightness:
                themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
          ),
          home: isLoggedIn ? const HomePage() : const LandingPage(),
        );
      },
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

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
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 400,
                ),
                const SizedBox(height: 30),
                const Text(
                  '',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildButton(context, 'Sign Up', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpPage()),
                      );
                    }),
                    const SizedBox(width: 20),
                    _buildButton(context, 'Login', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, String text, VoidCallback onPressed) {
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
        ),
      ),
    );
  }
}
