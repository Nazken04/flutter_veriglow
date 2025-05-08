import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome_page.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          Positioned(
            top: 60.0,
            left: 0,
            right: 0,
            child: Text(
              'VERIGLOW',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Aboreto',
                fontWeight: FontWeight.w400,
                fontSize: 30.0,
                height: 1.0, // For line-height: 100%
                letterSpacing: 0.0, // For letter-spacing: 0%
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            top: 550.0,
            left: 87.0,
            child: SizedBox(
              width: 200.0,
              height: 40.0,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xCCFAEDCD),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  // foregroundColor is inherited by the Text widget if not overridden
                  // We will set the color directly in the Text widget's style
                  // to ensure the font family also applies correctly.
                ),
                child: Text(
                  'LET\'S EXPLORE!',
                  style: TextStyle(
                    fontFamily: 'Aboreto',
                    fontWeight: FontWeight.w400,
                    fontSize: 20.0,
                    height: 1.0, // For line-height: 100%
                    letterSpacing: 0.0, // For letter-spacing: 0%
                    color: Color(0xFF3D3122), // A dark color for text, matching previous foregroundColor
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}