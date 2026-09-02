import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../widgets/navigation/staff_bottom_navigation_bar.dart';
import '../../widgets/navigation/staff_sidebar.dart';

class OperatorQrScannerPage extends StatefulWidget {
  const OperatorQrScannerPage({super.key});

  static const String routeName = '/operator-qr-scanner';

  @override
  State<OperatorQrScannerPage> createState() =>
      _OperatorQrScannerPageState();
}

class _OperatorQrScannerPageState extends State<OperatorQrScannerPage> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _bookingReferenceController =
  TextEditingController(
    text: 'NM-170926-1600-A1',
  );

  final MobileScannerController _scannerController =
  MobileScannerController(
    autoStart: false,
    formats: [
      BarcodeFormat.qrCode,
    ],
  );

  // ============================================================
  // STATE
  // ============================================================

  bool _cameraOpen = false;
  bool _isScanning = false;
  bool _bookingVerified = true;
  bool _visitorCheckedIn = false;

  String _visitorName = 'Alyssa Loh';
  String _visitorCount = '1 visitor';
  String _slotTime = '4:00 PM';
  String _attractionName = 'National Museum';

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _bookingReferenceController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // ============================================================
  // SIDEBAR NAVIGATION
  // ============================================================

  void _handleSidebarNavigation(int index) {
    for (final item in staffSidebarItems) {
      if (item.navigationIndex == index) {
        final String? routeName = item.routeName;

        if (routeName == null || routeName.isEmpty) {
          return;
        }

        if (routeName == OperatorQrScannerPage.routeName) {
          Navigator.pop(context);
          return;
        }

        Navigator.pushReplacementNamed(
          context,
          routeName,
        );

        return;
      }
    }
  }

  // ============================================================
  // FOOTER NAVIGATION
  // ============================================================

  void _handleBottomNavigation(int index) {
    if (index < 0 || index >= staffNavigationItems.length) {
      return;
    }

    final String? routeName =
        staffNavigationItems[index].routeName;

    if (routeName == null || routeName.isEmpty) {
      return;
    }

    if (routeName == OperatorQrScannerPage.routeName) {
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      routeName,
    );
  }

  // ============================================================
  // OPEN CAMERA
  // ============================================================

  Future<void> _openCamera() async {
    setState(() {
      _cameraOpen = true;
      _isScanning = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    try {
      await _scannerController.start();
    } on MobileScannerException catch (e) {
      debugPrint('MobileScanner error code: ${e.errorCode}');
      debugPrint('MobileScanner error: $e');

      if (!mounted) return;

      setState(() {
        _cameraOpen = false;
        _isScanning = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Camera error: ${e.errorCode}',
            ),
          ),
        );
    } catch (e) {
      debugPrint('Camera error: $e');

      if (!mounted) return;

      setState(() {
        _cameraOpen = false;
        _isScanning = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Camera error: $e',
            ),
          ),
        );
    }
  }
  // ============================================================
  // CLOSE CAMERA
  // ============================================================

  Future<void> _closeCamera() async {
    await _scannerController.stop();

    if (!mounted) return;

    setState(() {
      _cameraOpen = false;
      _isScanning = false;
    });
  }

  // ============================================================
  // QR DETECTED
  // ============================================================

  Future<void> _handleQrDetected(BarcodeCapture capture) async {
    if (!_isScanning) return;

    if (capture.barcodes.isEmpty) {
      return;
    }

    final String? scannedValue =
        capture.barcodes.first.rawValue;

    if (scannedValue == null ||
        scannedValue.trim().isEmpty) {
      return;
    }

    // Prevent repeated scanning
    _isScanning = false;

    await _scannerController.stop();

    if (!mounted) return;

    setState(() {
      _cameraOpen = false;

      _bookingReferenceController.text =
          scannedValue.trim();

      _bookingVerified = true;
      _visitorCheckedIn = false;

      // Prototype visitor information
      _visitorName = 'Alyssa Loh';
      _visitorCount = '1 visitor';
      _slotTime = '4:00 PM';
      _attractionName = 'National Museum';
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Booking QR scanned: ${scannedValue.trim()}',
          ),
        ),
      );
  }

  // ============================================================
  // MANUAL SEARCH
  // ============================================================

  void _searchBooking() {
    FocusScope.of(context).unfocus();

    final bookingReference =
    _bookingReferenceController.text.trim();

    if (bookingReference.isEmpty) {
      setState(() {
        _bookingVerified = false;
        _visitorCheckedIn = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter a booking reference.',
            ),
          ),
        );

      return;
    }

    setState(() {
      _bookingVerified = true;
      _visitorCheckedIn = false;

      // Prototype data
      _visitorName = 'Alyssa Loh';
      _visitorCount = '1 visitor';
      _slotTime = '4:00 PM';
      _attractionName = 'National Museum';
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Booking $bookingReference verified.',
          ),
        ),
      );
  }

  // ============================================================
  // CHECK-IN
  // ============================================================

  void _checkInVisitor() {
    if (!_bookingVerified || _visitorCheckedIn) {
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 42,
          ),
          title: const Text(
            'Confirm Check-In',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Confirm check-in for $_visitorName at $_attractionName?',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                setState(() {
                  _visitorCheckedIn = true;
                });

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Visitor checked in successfully.',
                      ),
                    ),
                  );
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                const Color(0xFFFFCD84),
                foregroundColor:
                const Color(0xFF79571E),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFFAF8FF),

      // ========================================================
      // SIDEBAR
      // ========================================================

      drawer: StaffSidebar(
        displayName: 'Operator',
        email: 'operator@tourflow.com',
        selectedIndex: 3,
        onItemSelected:
        _handleSidebarNavigation,
        onLogout: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/sign-in',
                (route) => false,
          );
        },
      ),

      // ========================================================
      // HEADER
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor:
        Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'QR Scanner',
              style: TextStyle(
                color: Color(0xFF131B2E),
                fontSize: 18,
                fontWeight:
                FontWeight.w800,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'TourFlow',
              style: TextStyle(
                color: Color(0xFF79571E),
                fontSize: 10,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding:
            EdgeInsets.only(right: 14),
            child: Center(
              child: _OperatorBadge(),
            ),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 760,
          ),
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              30,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                // =================================================
                // INTRODUCTION CARD
                // =================================================

                Container(
                  padding:
                  const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFEEF5FF),
                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Operator QR Scanner',
                        style: TextStyle(
                          color:
                          Color(0xFF3B82F6),
                          fontSize: 16,
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Scan a tourist booking QR code or search by booking reference.',
                        style: TextStyle(
                          color:
                          Color(0xFF475467),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration:
                        BoxDecoration(
                          color: const Color(
                            0xFF4285F4,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(20),
                        ),
                        child: const Text(
                          'OPERATOR MODE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // =================================================
                // CAMERA QR SCANNER
                // =================================================

                Container(
                  width: double.infinity,
                  height: 270,
                  clipBehavior:
                  Clip.antiAlias,
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFF111827),
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                  child: _cameraOpen
                      ? Stack(
                    fit:
                    StackFit.expand,
                    children: [
                      // ===========================
                      // REAL CAMERA
                      // ===========================

                      MobileScanner(
                        controller:
                        _scannerController,
                        onDetect:
                        _handleQrDetected,
                      ),

                      // ===========================
                      // SCAN AREA
                      // ===========================

                      Center(
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration:
                          BoxDecoration(
                            borderRadius:
                            BorderRadius
                                .circular(
                              14,
                            ),
                            border:
                            Border.all(
                              color:
                              const Color(
                                0xFF00E94F,
                              ),
                              width: 4,
                            ),
                          ),
                        ),
                      ),

                      // ===========================
                      // CLOSE BUTTON
                      // ===========================

                      Positioned(
                        top: 12,
                        right: 12,
                        child: Material(
                          color:
                          Colors.black54,
                          shape:
                          const CircleBorder(),
                          child:
                          IconButton(
                            onPressed:
                            _closeCamera,
                            icon:
                            const Icon(
                              Icons
                                  .close_rounded,
                              color:
                              Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // ===========================
                      // CAMERA TEXT
                      // ===========================

                      Positioned(
                        bottom: 14,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            Colors.black54,
                            borderRadius:
                            BorderRadius
                                .circular(
                              20,
                            ),
                          ),
                          child:
                          const Text(
                            'Point the camera at the tourist booking QR',
                            textAlign:
                            TextAlign
                                .center,
                            style:
                            TextStyle(
                              color:
                              Colors.white,
                              fontSize: 10,
                              fontWeight:
                              FontWeight
                                  .w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )

                  // =================================================
                  // CAMERA CLOSED
                  // =================================================

                      : Column(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration:
                        const BoxDecoration(
                          color:
                          Color(
                            0xFF1F2937,
                          ),
                          shape:
                          BoxShape.circle,
                        ),
                        child:
                        const Icon(
                          Icons
                              .qr_code_scanner_rounded,
                          color:
                          Colors.white,
                          size: 38,
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      const Text(
                        'Scan Tourist QR Code',
                        style:
                        TextStyle(
                          color:
                          Colors.white,
                          fontSize: 16,
                          fontWeight:
                          FontWeight
                              .w800,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      const Padding(
                        padding:
                        EdgeInsets
                            .symmetric(
                          horizontal: 20,
                        ),
                        child: Text(
                          'Use the camera to scan the tourist booking QR code.',
                          textAlign:
                          TextAlign
                              .center,
                          style:
                          TextStyle(
                            color:
                            Color(
                              0xFFCBD5E1,
                            ),
                            fontSize: 10,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      FilledButton.icon(
                        onPressed:
                        _openCamera,
                        style:
                        FilledButton
                            .styleFrom(
                          backgroundColor:
                          const Color(
                            0xFF4285F4,
                          ),
                          foregroundColor:
                          Colors.white,
                          elevation: 0,
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 20,
                            vertical: 11,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              22,
                            ),
                          ),
                        ),
                        icon:
                        const Icon(
                          Icons
                              .camera_alt_outlined,
                          size: 18,
                        ),
                        label:
                        const Text(
                          'Open Camera',
                          style:
                          TextStyle(
                            fontWeight:
                            FontWeight
                                .w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // =================================================
                // MANUAL BOOKING REFERENCE
                // =================================================

                TextField(
                  controller:
                  _bookingReferenceController,
                  onChanged: (_) {
                    if (_bookingVerified) {
                      setState(() {
                        _bookingVerified =
                        false;
                        _visitorCheckedIn =
                        false;
                      });
                    }
                  },
                  decoration:
                  InputDecoration(
                    labelText:
                    'Manual booking reference',
                    labelStyle:
                    const TextStyle(
                      color:
                      Color(0xFF667085),
                      fontSize: 11,
                    ),
                    hintText:
                    'Enter booking reference',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),

                    suffixIcon:
                    IconButton(
                      tooltip:
                      'Search booking',
                      onPressed:
                      _searchBooking,
                      icon: const Icon(
                        Icons.search_rounded,
                        color:
                        Color(
                          0xFF79571E,
                        ),
                      ),
                    ),

                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius
                          .circular(12),
                      borderSide:
                      const BorderSide(
                        color:
                        Color(
                          0xFFB8C1CF,
                        ),
                      ),
                    ),

                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius
                          .circular(12),
                      borderSide:
                      const BorderSide(
                        color:
                        Color(
                          0xFF79571E,
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // =================================================
                // VISITOR VERIFICATION
                // =================================================

                Container(
                  padding:
                  const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                    border: Border.all(
                      color:
                      const Color(
                        0xFFE0E2E8,
                      ),
                    ),
                  ),
                  child: _bookingVerified
                      ? Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Visitor Verification',
                              style:
                              TextStyle(
                                color:
                                Color(
                                  0xFF131B2E,
                                ),
                                fontSize:
                                13,
                                fontWeight:
                                FontWeight
                                    .w800,
                              ),
                            ),
                          ),

                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal:
                              13,
                              vertical:
                              6,
                            ),
                            decoration:
                            BoxDecoration(
                              color: _visitorCheckedIn
                                  ? const Color(
                                0xFFEFF6FF,
                              )
                                  : const Color(
                                0xFFECFDF3,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                20,
                              ),
                            ),
                            child: Row(
                              mainAxisSize:
                              MainAxisSize
                                  .min,
                              children: [
                                Icon(
                                  _visitorCheckedIn
                                      ? Icons
                                      .check_circle_rounded
                                      : Icons
                                      .circle,
                                  size: 8,
                                  color: _visitorCheckedIn
                                      ? const Color(
                                    0xFF2563EB,
                                  )
                                      : const Color(
                                    0xFF22C55E,
                                  ),
                                ),

                                const SizedBox(
                                  width: 6,
                                ),

                                Text(
                                  _visitorCheckedIn
                                      ? 'Checked In'
                                      : 'Valid',
                                  style:
                                  TextStyle(
                                    color: _visitorCheckedIn
                                        ? const Color(
                                      0xFF2563EB,
                                    )
                                        : const Color(
                                      0xFF16A34A,
                                    ),
                                    fontSize:
                                    10,
                                    fontWeight:
                                    FontWeight
                                        .w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 11,
                      ),

                      Text(
                        '$_visitorName · $_visitorCount · $_slotTime slot',
                        style:
                        const TextStyle(
                          color:
                          Color(
                            0xFF475467,
                          ),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        _attractionName,
                        style:
                        const TextStyle(
                          color:
                          Color(
                            0xFF667085,
                          ),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  )
                      : const Row(
                    children: [
                      Icon(
                        Icons
                            .info_outline_rounded,
                        color:
                        Color(
                          0xFF667085,
                        ),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Scan a QR code or search a booking reference to verify the visitor.',
                          style:
                          TextStyle(
                            color:
                            Color(
                              0xFF667085,
                            ),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // =================================================
                // CHECK-IN BUTTON
                // =================================================

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child:
                  FilledButton.icon(
                    onPressed:
                    !_bookingVerified ||
                        _visitorCheckedIn
                        ? null
                        : _checkInVisitor,

                    style:
                    FilledButton
                        .styleFrom(
                      backgroundColor:
                      const Color(
                        0xFFFFCD84,
                      ),
                      foregroundColor:
                      const Color(
                        0xFF79571E,
                      ),
                      disabledBackgroundColor:
                      const Color(
                        0xFFE9E5DE,
                      ),
                      disabledForegroundColor:
                      const Color(
                        0xFF98A2B3,
                      ),
                      elevation: 0,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(9),
                      ),
                    ),

                    icon: Icon(
                      _visitorCheckedIn
                          ? Icons
                          .check_circle_outline
                          : Icons
                          .login_rounded,
                      size: 20,
                    ),

                    label: Text(
                      _visitorCheckedIn
                          ? 'Visitor Checked In'
                          : 'Check-In Visitor',
                      style:
                      const TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ========================================================
      // FOOTER
      // ========================================================

      bottomNavigationBar:
      StaffBottomNavigationBar(
        selectedIndex: 3,
        onItemSelected:
        _handleBottomNavigation,
      ),
    );
  }
}

// ============================================================
// OPERATOR BADGE
// ============================================================

class _OperatorBadge
    extends StatelessWidget {
  const _OperatorBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFFFF6E8),
        border: Border.all(
          color:
          const Color(0xFFE8D3B7),
        ),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: const Text(
        'OPERATOR',
        style: TextStyle(
          color:
          Color(0xFF79571E),
          fontSize: 10,
          fontWeight:
          FontWeight.w700,
        ),
      ),
    );
  }
}