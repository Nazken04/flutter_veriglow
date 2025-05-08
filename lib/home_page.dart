import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    // For more control over when detection happens if needed:
    // detectionTimeoutMs: 1000, // Example: only one detection per second
  );
  bool _isScanningMode = true;
  Map<String, dynamic>? _productDataFromBackend;
  String? _verificationMessage; // This will store the "message" from the backend

  final storage = FlutterSecureStorage();
  // IMPORTANT: Replace this with your actual, current ngrok URL every time you restart ngrok.
  final String _baseNgrokUrl = 'https://f98a-46-34-192-109.ngrok-free.app';

  @override
  void initState() {
    super.initState();
    // Optionally, ensure the camera starts if in scanning mode and not already running
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted && _isScanningMode && cameraController.value.isRunning == false) {
    //     try { cameraController.start(); } catch (e) { print("Error starting camera in initState: $e");}
    //   }
    // });
  }

  Future<String?> _getAuthToken() async {
    return await storage.read(key: 'jwt_token');
  }

  Future<void> _fetchProductInfo(String qrCodeValue) async {
    // Indicate loading to the user if you have a loading state variable
    // if (mounted) setState(() { _isLoading = true; });

    final token = await _getAuthToken();
    if (!mounted) return; // Check mounted after await

    if (token == null) {
      setState(() {
        _verificationMessage = 'Authentication error. Please log in again.';
        _isScanningMode = true; // Stay in scanning mode to show error
        _productDataFromBackend = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication error. Please log in again.')));
      // Attempt to restart camera for next scan attempt if it's not running
      if (mounted && cameraController.value.isRunning == false) {
        try { await cameraController.start(); } catch (e) { print("Error restarting camera (auth fail): $e"); }
      }
      // if (mounted) setState(() { _isLoading = false; });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseNgrokUrl/api/products/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'qr_code': qrCodeValue}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _productDataFromBackend = responseData['product'];
          _verificationMessage = responseData['message']; // Store the backend message
          _isScanningMode = false; // Switch to product display mode
        });
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _verificationMessage =
          'Failed: ${response.statusCode} - ${errorData['message'] ?? 'Unknown error'}';
          _productDataFromBackend = null;
          _isScanningMode = true; // Stay in scanning mode to show error
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_verificationMessage ?? 'Failed to fetch product info')));
        if (mounted && cameraController.value.isRunning == false) {
          try { await cameraController.start(); } catch (e) { print("Error restarting camera (fetch fail): $e"); }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verificationMessage = 'Error: $e';
        _productDataFromBackend = null;
        _isScanningMode = true; // Stay in scanning mode
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      if (mounted && cameraController.value.isRunning == false) {
        try { await cameraController.start(); } catch (e) { print("Error restarting camera (exception): $e"); }
      }
    } finally {
      // if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _handleBarcodeDetect(BarcodeCapture capture) {
    // Only process if in scanning mode and widget is still mounted
    if (!_isScanningMode || !mounted) return;

    final Barcode barcode = capture.barcodes.first;
    if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
      // Stop the camera to prevent multiple detections while processing current one
      // It's important to check if the controller might have been disposed
      // though 'mounted' check should largely cover this.
      // The controller itself handles not operating if disposed.
      cameraController.stop();
      _fetchProductInfo(barcode.rawValue!);
    }
  }

  void _resetToScanMode() {
    if (!mounted) return;
    setState(() {
      _productDataFromBackend = null;
      _verificationMessage = null; // Clear previous verification message
      _isScanningMode = true;
    });

    // If camera is not running, try to start it.
    // This will be relevant if the user taps the back arrow or the QR icon in nav bar
    // while product details are shown.
    if (mounted && cameraController.value.isRunning == false) {
      try {
        cameraController.start();
      } catch (e) {
        print("Error starting camera in _resetToScanMode: $e");
        // Potentially show an error to the user if camera fails to start
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not start camera. Please check permissions.')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE5DFD9),
      body: Stack(
        children: [
          _isScanningMode
              ? _buildScannerUI(context)
              : _buildProductDetailsUI(context),
          _buildBottomNavigationBar(context),
        ],
      ),
    );
  }

  Widget _buildScannerUI(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.only(bottom: 88.0 + 10.0), // Space for bottom nav + margin
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 20), // Status bar + padding
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.transparent, // Or a very subtle background
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 4.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Veriglow QR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Aboreto',
                  fontWeight: FontWeight.w400,
                  fontSize: 30.0,
                  height: 1.0,
                  letterSpacing: 0.0,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!mounted) return;
                      // If user taps this area, ensure scanning mode is active and camera tries to start
                      if (!_isScanningMode) {
                        _resetToScanMode(); // This will set _isScanningMode to true and try to start camera
                      } else if (cameraController.value.isRunning == false) {
                        try {
                          cameraController.start();
                        } catch (e) {
                          print("Error starting camera on tap: $e");
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Camera not available.')));
                          }
                        }
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/qrcode.png',
                          width: 120,
                          height: 120,
                          color: Color(0xFF6A4F1D),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Tap to check',
                          style: TextStyle(
                            fontFamily: 'Aboreto',
                            fontWeight: FontWeight.w400,
                            fontSize: 20.0,
                            height: 1.0,
                            letterSpacing: 0.0,
                            color: Colors.black.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Text(
                            'You can see the product information after scanning the QR code',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              fontSize: 12.0,
                              height: 1.2,
                              letterSpacing: 0.0,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: screenHeight * 0.30,
                    width: screenWidth * 0.75,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400, width: 1),
                        borderRadius: BorderRadius.circular(12)
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11.0), // Match inner border
                      child: MobileScanner(
                        controller: cameraController,
                        onDetect: _handleBarcodeDetect,
                        // Consider adding an error builder for the scanner itself
                        // errorBuilder: (context, error, child) {
                        //   return Center(child: Text('Camera error: ${error.errorDetails?.message}'));
                        // },
                      ),
                    ),
                  ),
                  if (_verificationMessage != null && _productDataFromBackend == null) // Error from backend
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                        _verificationMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetailsUI(BuildContext context) {
    if (_productDataFromBackend == null) {
      // This case should ideally not be reached if _isScanningMode is false,
      // but as a fallback, show scanner UI or a loading/error state.
      return _buildScannerUI(context);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final String imageUrl = _productDataFromBackend!['image_url'] ?? '';
    // Determine authenticity based on the backend's message content
    final bool isWarning = _verificationMessage?.toLowerCase().contains('warning') ?? false;

    return Stack(
      children: [
        // Background Product Image
        Positioned(
          // top: -92.0, // Absolute positioning can be tricky for responsiveness
          // left: -5.0,
          // width: 381.0,
          top: 0,
          left: 0,
          right: 0,
          height: screenHeight * 0.55, // Adjusted to be more responsive
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey.shade300, child: Center(child: CircularProgressIndicator(color: Color(0xFF6A4F1D)))),
            errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: Icon(Icons.broken_image, size: 100, color: Colors.grey.shade400)),
          )
              : Container( // Placeholder if no image_url
              height: screenHeight * 0.55,
              color: Colors.grey.shade300,
              child: Center(child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey.shade400))),
        ),

        // Back Arrow to reset to scanner
        Positioned(
          top: 24.0 + MediaQuery.of(context).padding.top, // Consider status bar
          left: 11.0,
          child: Container(
            width: 45.0,
            height: 45.0,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4), // Background for visibility
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: _resetToScanMode,
            ),
          ),
        ),

        // "PRODUCT INFORMATION" Text
        Positioned(
          top: 37.0 + MediaQuery.of(context).padding.top, // Consider status bar
          // left: 84.0, // Let's center it instead for better responsiveness
          left: 0,
          right: 0,
          child: Center( // Center the text container
            child: Container(
              width: 250.0, // Adjusted width
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Adjusted padding
              decoration: BoxDecoration(
                  color: Color(0xB394AFC9), // Color with some transparency
                  borderRadius: BorderRadius.circular(10), // Softer radius
                  // Simulating inset shadow:
                  // No direct inset, but a slight outer shadow can look good
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25), // Outer shadow
                      blurRadius: 6.0,
                      offset: Offset(0, 2),
                    )
                  ]
              ),
              child: Text(
                'PRODUCT INFORMATION',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Aboreto',
                    fontWeight: FontWeight.w600, // Bolder
                    fontSize: 22.0, // Bigger
                    height: 1.0,
                    letterSpacing: 0.0, // Or a very slight positive for Aboreto
                    color: Colors.white,
                    shadows: [ // Text shadow for better readability on image
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: Offset(1.0, 1.0),
                      ),
                    ]
                ),
              ),
            ),
          ),
        ),

        // Product Information Card
        Positioned(
          top: screenHeight * 0.55 - 50, // Pull card up to overlap image more
          left: 0, // Full width for the card container initially
          right: 0,
          bottom: 88.0 + 10, // Space for nav bar
          child: Container(
            // width: 375.0, // Width will be constrained by screen or a max-width child
            // height: screenHeight * 0.5 + 40 - (88+10), // Height will be dynamic
            decoration: BoxDecoration(
              color: Color(0xFF94AFC9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(42.0),
                topRight: Radius.circular(42.0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25.0, 25.0, 25.0, 10.0), // Adjusted padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name & Authenticity Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
                    children: [
                      Expanded(
                        flex: 3, // Give more space to product name
                        child: Container(
                          // decoration for product name's shadow - applied to container
                          decoration: BoxDecoration(
                            // color: Colors.black.withOpacity(0.1), // Subtle bg for text shadow effect
                            // borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x30000000), // Softer shadow
                                blurRadius: 5.0,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding( // Padding inside the shadow container
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              _productDataFromBackend!['product_name'] ?? 'Unknown Product',
                              style: TextStyle(
                                fontFamily: 'Aboreto',
                                fontWeight: FontWeight.w400, // As per spec
                                fontSize: 25.0, // As per spec
                                height: 1.1,
                                letterSpacing: 0.0,
                                color: Color(0xFFFFFFFF),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Container(
                        width: 110, // Slightly wider
                        height: 48,  // Taller for better tap target
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFFE5DFD9), // As per spec
                          borderRadius: BorderRadius.circular(16.0), // As per spec
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4.0,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            isWarning ? 'Warning!' : 'Original', // From backend message
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600, // Bolder
                              fontSize: 17.0, // Bigger
                              height: 1.0,
                              letterSpacing: 0.0,
                              color: isWarning ? Colors.red.shade800 : Colors.green.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18), // Increased spacing

                  // Other Information Section
                  Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_verificationMessage != null && _verificationMessage!.isNotEmpty && isWarning)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Text(
                                _verificationMessage!, // Display the backend "Warning..." message
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.red.shade800),
                              ),
                            )
                          else if (_verificationMessage != null && _verificationMessage!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Text(
                                _verificationMessage!, // Display "Product verification successful"
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 14.5, fontWeight: FontWeight.w500, color: Colors.black.withOpacity(0.95)),
                              ),
                            ),

                          _buildInfoDetailRow('Batch No:', _productDataFromBackend!['batch_number']),
                          _buildInfoDetailRow('Manufacture Date:', _productDataFromBackend!['manufacturing_date']),
                          _buildInfoDetailRow('Expiry Date:', _productDataFromBackend!['expiry_date']),
                          _buildInfoDetailRow('Ingredients:', _productDataFromBackend!['ingredients']),
                          SizedBox(height: 12),
                          Text(
                            'Scan History for this Product:',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700, // As per spec
                                fontSize: 15.0, // Slightly bigger
                                color: Colors.black.withOpacity(0.9)),
                          ),
                          SizedBox(height: 6),
                          if (_productDataFromBackend!['scanHistory'] != null && (_productDataFromBackend!['scanHistory'] as List).isNotEmpty)
                            Container(
                              constraints: BoxConstraints(maxHeight: 150), // Limit height of scan history
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: (_productDataFromBackend!['scanHistory'] as List).length,
                                itemBuilder: (context, index) {
                                  final scanEntry = (_productDataFromBackend!['scanHistory'] as List)[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                                    child: Text("- $scanEntry", style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, color: Colors.black.withOpacity(0.85))),
                                  );
                                },
                              ),
                            )
                          else
                            Text("No previous scans recorded for this item.", style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontStyle: FontStyle.italic, color: Colors.black.withOpacity(0.7))),
                          SizedBox(height: 10), // Space at the bottom of scroll view
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0), // Increased vertical padding
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14.0, // As per spec for "other information"
            height: 1.4, // Improved line height for readability
            letterSpacing: 0.0, // As per spec
            color: Colors.white.withOpacity(0.9), // White text on dark card
          ),
          children: [
            TextSpan(text: '$label ', style: TextStyle(fontWeight: FontWeight.w700)), // As per spec
            TextSpan(text: value ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Positioned(
      left: -10.0, // As per spec
      bottom: 0,
      child: Container(
        width: 385.0, // As per spec
        height: 88.0, // As per spec
        decoration: BoxDecoration(
          color: Color(0xFFE5DFD9), // As per spec
          boxShadow: [
            BoxShadow(
              color: Color(0x40000000), // As per spec
              blurRadius: 4.0,
              offset: Offset(0, -4), // Shadow appears above
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Image.asset('assets/images/img_1.png', width: 40, height: 40),
              onPressed: _resetToScanMode, // QR icon resets to scanning mode
            ),
            IconButton(
              icon: Image.asset('assets/images/img.png', width: 40, height: 40),
              onPressed: () {
                if (mounted) {
                  Navigator.pushNamed(context, '/profile');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}