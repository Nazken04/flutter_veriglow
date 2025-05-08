import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import flutter_secure_storage

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final storage = FlutterSecureStorage(); // Create storage instance

  Future<void> _login() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    // IMPORTANT: Always use your current ngrok URL
    String ngrokUrl = 'https://f98a-46-34-192-109.ngrok-free.app'; // Replace this

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please enter email and password')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$ngrokUrl/api/auth/login'), // Use the variable
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Login successful, parse the response to get the token
        final responseData = json.decode(response.body);
        final String? token = responseData['token'];

        if (token != null && token.isNotEmpty) {
          // Store the token securely
          await storage.write(key: 'jwt_token', value: token);
          print('Login successful, token stored: $token'); // For debugging

          // Navigate to home page
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Token was not in the response, this is an unexpected server response
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Login successful but no token received.')));
          print('Login successful but no token found in response: ${response.body}');
        }
      } else {
        // Handle error
        String errorMessage = 'Login failed. Status: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = json.decode(response.body);
            if (errorData['message'] != null) {
              errorMessage += '\nServer: ${errorData['message']}';
            } else if (errorData['error'] != null) {
              errorMessage += '\nServer: ${errorData['error']}';
            } else {
              errorMessage += '\nBody: ${response.body}';
            }
          } catch (e) {
            errorMessage += '\nBody: ${response.body}';
          }
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
        print('Login failed. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Error during login: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE5DFD9),
      body: Stack(
        children: [
          Positioned(
            top: 185.0,
            left: 41.0,
            child: SizedBox(
              width: 292.0,
              height: 76.0,
              child: Text(
                'Smart beauty starts here! Verify, trust, and glow with confidence.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Aboreto',
                  fontWeight: FontWeight.w400,
                  fontSize: 20.0,
                  height: 1.0,
                  letterSpacing: 0.0,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Positioned(
            top: 276.0,
            left: 41.0,
            child: Container(
              width: 296.0,
              height: 229.0,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              decoration: BoxDecoration(
                color: Color(0x80FFFFFF),
                borderRadius: BorderRadius.circular(30.0),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 4.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _emailController,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      fontSize: 17.0,
                      height: 1.0,
                      letterSpacing: 0.0,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        fontSize: 17.0,
                        height: 1.0,
                        letterSpacing: 0.0,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      fontSize: 17.0,
                      height: 1.0,
                      letterSpacing: 0.0,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        fontSize: 17.0,
                        height: 1.0,
                        letterSpacing: 0.0,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6A4F1D),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      'Log in',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 20.0,
                        height: 1.0,
                        letterSpacing: 0.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 505.0 + 15,
            left: 0,
            right: 0,
            child: Column(
              children: [
                TextButton(
                  onPressed: () {
                  },
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 11.0,
                      height: 1.0,
                      letterSpacing: 0.0,
                      color: Colors.blue,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        fontSize: 13.0,
                        height: 1.0,
                        letterSpacing: 0.0,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(50, 20),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13.0,
                          height: 1.0,
                          letterSpacing: 0.0,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Image.asset(
                        'assets/images/google_icon.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                      onPressed: () {
                      },
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      icon: Image.asset(
                        'assets/images/facebook_icon.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                      onPressed: () {
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}