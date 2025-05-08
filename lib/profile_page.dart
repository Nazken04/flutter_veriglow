import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // For date formatting

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'User'; // Default
  List<dynamic> _scanHistory = [];
  bool _isLoading = true;
  String? _errorMessage;
  final storage = FlutterSecureStorage();

  // IMPORTANT: Replace with your ACTUAL and CURRENT ngrok URL
  final String _baseNgrokUrl = 'https://f98a-46-34-192-109.ngrok-free.app';

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
  }

  Future<String?> _getAuthToken() async {
    return await storage.read(key: 'jwt_token');
  }

  Future<void> _loadAllUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = await _getAuthToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication required. Please log in.';
      });
      return;
    }

    try {
      // Fetch profile details (like name)
      final profileResponse = await http.get(
        Uri.parse('$_baseNgrokUrl/api/auth/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (profileResponse.statusCode == 200) {
        final profileData = json.decode(profileResponse.body);
        setState(() {
          _userName = profileData['name'] ?? 'User';
        });
      } else {
        // Handle profile fetch error but still try to get scan history
        print('Failed to fetch profile: ${profileResponse.statusCode}');
      }

      // Fetch scan history
      final scanHistoryResponse = await http.get(
        Uri.parse('$_baseNgrokUrl/api/auth/scan-history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (scanHistoryResponse.statusCode == 200) {
        final scanHistoryData = json.decode(scanHistoryResponse.body);
        setState(() {
          _scanHistory = scanHistoryData['scanHistory'] ?? [];
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load scan history (${scanHistoryResponse.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatScanTime(String? timeString) {
    if (timeString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(timeString);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
    } catch (e) {
      return timeString; // Return original if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFFE5DFD9),
      body: Stack(
        children: [
          Positioned(
            top: 30.0,
            left: 216.0,
            child: SizedBox(
              width: 136.0, // Max width
              height: 28.0,
              child: Text(
                'Hi, $_userName!',
                style: TextStyle(
                  fontFamily: 'Aboreto',
                  fontWeight: FontWeight.w400,
                  fontSize: 24.0,
                  height: 1.0,
                  letterSpacing: -0.3,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis, // Handle long names
              ),
            ),
          ),
          Positioned(
            top: 65.0,
            left: 216.0,
            child: SizedBox(
              width: 80.0,
              height: 19.0,
              child: Text(
                'Welcome',
                style: TextStyle(
                  fontFamily: 'Aboreto',
                  fontWeight: FontWeight.w400,
                  fontSize: 16.0,
                  height: 1.0,
                  letterSpacing: -0.3,
                  color: Colors.black54,
                ),
              ),
            ),
          ),

          // Main content area for scan history
          Padding(
            padding: EdgeInsets.only(
              top: 110.0, // Space below "Welcome" text
              bottom: 88.0 + 10.0, // Space for bottom nav + margin
              left: 20.0,
              right: 20.0,
            ),
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Color(0xFF6A4F1D)))
                : _errorMessage != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 16)),
              ),
            )
                : _scanHistory.isEmpty
                ? Center(
              child: Text(
                'No scans available.\nStart scanning QR codes to view your history.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.0,
                  color: Colors.black54,
                ),
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0, top: 10.0),
                  child: Text(
                    'Your Scan History',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.8)
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _scanHistory.length,
                    itemBuilder: (context, index) {
                      final scan = _scanHistory[index];
                      final product = scan['product'];
                      if (product == null) return SizedBox.shrink(); // Should not happen if backend populates correctly

                      return Card(
                        elevation: 2.0,
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        color: Colors.white.withOpacity(0.9),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(12.0),
                          leading: product['image_url'] != null && product['image_url'].isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              product['image_url'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(width: 60, height: 60, color: Colors.grey.shade300, child: Icon(Icons.broken_image, color: Colors.grey.shade600)),
                            ),
                          )
                              : Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Icon(Icons.image_not_supported, color: Colors.grey.shade600),
                          ),
                          title: Text(
                            product['product_name'] ?? 'Unknown Product',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 16.0,
                            ),
                          ),
                          subtitle: Text(
                            'Scanned: ${_formatScanTime(scan['time'])}\nLocation: ${scan['location'] ?? 'N/A'}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13.0,
                              color: Colors.black54,
                            ),
                          ),
                          // Trailing could be used for more info or an icon
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Bottom Navigation Panel (same as HomePage)
          Positioned(
            left: -10.0,
            bottom: 0,
            child: Container(
              width: 385.0,
              height: 88.0,
              decoration: BoxDecoration(
                color: Color(0xFFE5DFD9),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 4.0,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Image.asset('assets/images/img_1.png', width: 40, height: 40),
                    onPressed: () {
                      // Navigate to QR Scan Page (HomePage)
                      // Use pushReplacementNamed if you don't want ProfilePage in back stack
                      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                    },
                  ),
                  IconButton(
                    icon: Image.asset('assets/images/img.png', width: 40, height: 40),
                    onPressed: () {
                      // Already on Profile Page, do nothing or refresh
                      _loadAllUserData();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}