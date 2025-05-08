import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui'; // Required for ImageFilter

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _register() async {
    String name = _nameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all fields')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://f98a-46-34-192-109.ngrok-free.app/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        String errorMessage = 'Registration failed. Status: ${response.statusCode}';
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
        print('Registration failed. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Error during registration: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        fontSize: 17.0,
        height: 1.0,
        letterSpacing: 0.0,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          fontSize: 17.0,
          height: 1.0,
          letterSpacing: 0.0,
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[700]) : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
        isDense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFFE5DFD9),
      body: Stack(
        children: [
          Positioned(
            top: 40, // Adjusted for status bar
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black54),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Positioned(
            top: 56.0,
            left: 119.0,
            child: SizedBox(
              width: 138.0,
              height: 84.0, // Increased height to allow for multiple lines if text wraps
              child: Text(
                'CREATE NEW ACCOUNT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Aboreto',
                  fontWeight: FontWeight.w400,
                  fontSize: 24.0,
                  height: 1.0, // line-height: 100%
                  letterSpacing: 0.0,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Positioned(
            top: 180.0,
            left: 40.0,
            child: Container(
              width: 296.0,
              height: 321.0,
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
              decoration: BoxDecoration(
                color: Color(0x80FFFFFF), // #FFFFFF80
                borderRadius: BorderRadius.circular(30.0),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000), // #00000040
                    blurRadius: 4.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    labelText: 'Name',
                    prefixIcon: Icons.person_outline,
                  ),
                  _buildTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email_outlined,
                  ),
                  _buildTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey[700],
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sign Up Button - Positioned below the form
          // Form ends at 180 (top) + 321 (height) = 501. Add some spacing.
          Positioned(
            top: 501.0 + 30.0, // 30px below the form
            left: (screenWidth - 220) / 2, // Centering the button (adjust width if needed)
            child: Container(
              width: 220, // Specify a width for the button's container
              height: 50,  // Specify a height
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0), // Match button shape
                boxShadow: [
                  BoxShadow(
                    color: Color(0x26000000), // #00000026
                    blurRadius: 30.0,
                    offset: Offset(0, 30),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Adjusted blur from 60px
                  child: ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xAAE5DFD9), // #E5DFD9CC, slightly more opaque for text
                      elevation: 0, // Shadow handled by outer Container
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: Text(
                      'Sign up',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 20.0,
                        height: 1.0,
                        letterSpacing: 0.0,
                        color: Colors.black.withOpacity(0.75), // Darker text for readability
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // "Already using VeriGlow? Sign in" - Positioned below the button
          // Button is at top: 531, height: 50. Ends at 581. Add spacing.
          Positioned(
            top: 581.0 + 25.0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already using VeriGlow? ",
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
                    Navigator.pushNamed(context, '/login');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(50, 20),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Sign in',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 13.0,
                      height: 1.0,
                      letterSpacing: 0.0,
                      color: Theme.of(context).primaryColorDark, // Or a specific color
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}