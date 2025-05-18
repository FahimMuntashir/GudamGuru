import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
import 'dart:convert';

import 'login.dart';

class OTPPage extends StatefulWidget {
  final String phone;
  const OTPPage({super.key, required this.phone});

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final TextEditingController otpController = TextEditingController();

  // Future<void> verifyOTP() async {
  //   var url = Uri.parse('https://yourserver.com/verify_otp.php');
  //   var response = await http.post(url, body: {
  //     'phone': widget.phone,
  //     'otp': otpController.text,
  //   });

  //   var data = json.decode(response.body);
  //   if (data['status'] == 'success') {
  //     Navigator.pushReplacement(
  //         context, MaterialPageRoute(builder: (context) => LoginPage()));
  //   } else {
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text(data['message'])));
  //   }
  //   if (otpController.text == '111111') {
  //     Navigator.pushReplacement(
  //         context, MaterialPageRoute(builder: (context) => LoginPage()));
  //   } else {
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text('Success')));
  //   }
  // }
  Future<void> verifyOTP() async {
    if (otpController.text == '111111') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginPage()));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid OTP')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              opacity: const AlwaysStoppedAnimation(0.2),
              fit: BoxFit.cover,
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
                width: 300,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _buildTextField(otpController, 'Enter OTP'),
                    ElevatedButton(
                        onPressed: verifyOTP, child: Text('Verify OTP')),
                    TextButton(
                      onPressed: () {
                        // Optional: Implement resend logic here
                      },
                      child: Text('Resend OTP'),
                    )
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

Widget _buildTextField(TextEditingController controller, String hint) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
  );
}

Widget _buildButton(
    BuildContext context, String text, Color color, VoidCallback onPressed) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
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
