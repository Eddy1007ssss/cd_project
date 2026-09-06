import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/tourflow_widgets.dart';

class StaffQrScannerPage extends StatefulWidget {
  const StaffQrScannerPage({
    this.gateway,
    super.key,
  });

  static const String routeName = TourFlowRoutes.staffScan;

  final StaffCheckInGateway? gateway;

  @override
  State<StaffQrScannerPage> createState() =>
      _StaffQrScannerPageState();
}

class _StaffQrScannerPageState extends State<StaffQrScannerPage> {
  final TextEditingController _bookingCodeController =
  TextEditingController();

  final MobileScannerController _scannerController =
  MobileScannerController(
    autoStart: false,
    formats: const [
      BarcodeFormat.qrCode,
    ],
  );

  bool _cameraOpen = false;
  bool _acceptingScan = false;
  bool _isBusy = false;
  bool _sheetOpen = false;

  String? _latestLookupValue;
  StaffBookingVerification? _latestResult;

  StaffCheckInGateway get _gateway =>
      widget.gateway ?? EngagementRepository();

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _bookingCodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // ============================================================
  // OPEN CAMERA
  // ============================================================

  Future<void> _openCamera() async {
    if (_isBusy || _sheetOpen || _cameraOpen) {
      return;
    }

    setState(() {
      _cameraOpen = true;
      _acceptingScan = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 250),
    );

    if (!mounted || !_cameraOpen) {
      return;
    }

    try {
      await _scannerController.start();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cameraOpen = false;
        _acceptingScan = false;
      });

      _showMessage(
        'Unable to open the camera. Check camera permission '
            'or enter the booking code manually.',
      );
    }
  }

  // ============================================================
  // CLOSE CAMERA
  // ============================================================

  Future<void> _closeCamera() async {
    _acceptingScan = false;

    try {
      await _scannerController.stop();
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Unable to stop the camera. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cameraOpen = false;
        });
      }
    }
  }

  // ============================================================
  // HANDLE QR DETECTED
  // ============================================================

  Future<void> _handleQrDetected(
      BarcodeCapture capture,
      ) async {
    if (!_acceptingScan || _isBusy || _sheetOpen) {
      return;
    }

    String? value;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();

      if (rawValue != null && rawValue.isNotEmpty) {
        value = rawValue;
        break;
      }
    }

    if (value == null) {
      return;
    }

    _acceptingScan = false;

    await _verify(
      scannedValue: value,
      updateInput: true,
    );
  }

  // ============================================================
  // VERIFY BOOKING
  //
  // updateInput = true
  // Normal Verify / QR Scan:
  // booking code may be shown in the input.
  //
  // updateInput = false
  // View button:
  // refresh booking status but NEVER touch input.
  // ============================================================

  Future<void> _verify({
    String? scannedValue,
    bool updateInput = true,
  }) async {
    if (!mounted || _isBusy || _sheetOpen) {
      return;
    }

    FocusScope.of(context).unfocus();

    final lookupValue =
    (scannedValue ?? _bookingCodeController.text).trim();

    setState(() {
      _isBusy = true;
      _acceptingScan = false;
    });

    StaffBookingVerification? verification;

    try {
      if (_cameraOpen) {
        await _closeCamera();

        if (!mounted) {
          return;
        }
      }

      final result = lookupValue.isEmpty
          ? StaffBookingVerification.invalid()
          : await _gateway.verifyStaffBooking(
        lookupValue,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _latestResult = result;
        _latestLookupValue = lookupValue;

        // Only normal Verify / QR scan is allowed
        // to change the visible input field.
        if (updateInput) {
          final bookingCode = result.bookingCode;

          if (bookingCode != null && bookingCode.isNotEmpty) {
            _bookingCodeController.text = bookingCode;
          }
        }
      });

      verification = result;
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (error.toString().contains('STAFF_ACCESS_DENIED')) {
        _showMessage(
          'Please sign in using an active Staff account.',
        );
      } else {
        _showMessage(
          'Unable to verify this booking. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }

    if (mounted && verification != null) {
      await _showVerification(
        verification,
      );
    }
  }

  // ============================================================
  // CONFIRM CHECK-IN / CHECK-OUT
  // ============================================================

  Future<void> _confirm(
      StaffBookingVerification booking,
      ) async {
    final bookingId = booking.bookingId;

    if (!mounted || bookingId == null || _isBusy) {
      return;
    }

    if (!booking.canCheckIn && !booking.canCheckOut) {
      return;
    }

    final checkingOut = booking.canCheckOut;

    setState(() {
      _isBusy = true;
    });

    try {
      final result = checkingOut
          ? await _gateway.confirmStaffCheckOut(
        bookingId,
      )
          : await _gateway.confirmStaffCheckIn(
        bookingId,
      );

      if (!mounted) {
        return;
      }

      final succeeded = checkingOut
          ? result.status == StaffBookingStatus.checkedOut
          : result.status == StaffBookingStatus.checkedIn;

      setState(() {
        // Keep latest result so the bottom card stays visible.
        _latestResult = result;

        // Keep booking code internally so View still works.
        final bookingCode = result.bookingCode;

        if (bookingCode != null && bookingCode.isNotEmpty) {
          _latestLookupValue = bookingCode;
        }

        // ====================================================
        // ONLY SUCCESSFUL CHECK-IN / CHECK-OUT CLEARS INPUT
        // ====================================================

        if (succeeded) {
          _bookingCodeController.clear();
        }
      });

      if (succeeded) {
        FocusScope.of(context).unfocus();

        await _showSuccess(
          result,
        );
      } else {
        _showMessage(
          _statusMessage(result.status),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      final action = checkingOut ? 'Check-out' : 'Check-in';

      if (error.toString().contains('STAFF_ACCESS_DENIED')) {
        _showMessage(
          'Please sign in using an active Staff account.',
        );
      } else {
        _showMessage(
          '$action could not be confirmed. Verify the booking again '
              'to check its latest status.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  // ============================================================
  // SHOW VERIFICATION SHEET
  // ============================================================

  Future<void> _showVerification(
      StaffBookingVerification result,
      ) async {
    if (!mounted || _sheetOpen) {
      return;
    }

    setState(() {
      _sheetOpen = true;
    });

    bool? confirmed;

    try {
      confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => _VerificationSheet(
          result: result,
          onConfirm: result.canCheckIn || result.canCheckOut
              ? () {
            Navigator.pop(
              sheetContext,
              true,
            );
          }
              : null,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sheetOpen = false;
        });
      }
    }

    if (confirmed == true && mounted) {
      await _confirm(result);
    }
  }

  // ============================================================
  // SHOW SUCCESS SHEET
  // ============================================================

  Future<void> _showSuccess(
      StaffBookingVerification result,
      ) async {
    if (!mounted) {
      return;
    }

    final checkedOut =
        result.status == StaffBookingStatus.checkedOut;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 56,
                color: TourFlowColors.success,
              ),

              const SizedBox(height: 12),

              Text(
                checkedOut
                    ? 'Check-Out Successful'
                    : 'Check-In Successful',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                checkedOut
                    ? '${result.visitorName ?? 'Visitor'} '
                    'has been checked out.'
                    : '${result.visitorName ?? 'Visitor'} '
                    'has been checked in.',
                textAlign: TextAlign.center,
              ),

              if (checkedOut) ...[
                const SizedBox(height: 8),

                const Text(
                  'The booking is completed. '
                      'The tourist can now submit feedback.',
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 16),

              Text(
                'Current visitor count: '
                    '${result.currentVisitorCount ?? 0}',
                key: const Key(
                  'current-visitor-count',
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      sheetContext,
                    );
                  },
                  child: const Text(
                    'Done',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final controlsDisabled = _isBusy || _sheetOpen;

    return TourFlowPage(
      title: 'Scan QR',
      role: 'TOURFLOW · STAFF',
      navigationRole: TourFlowNavigationRole.staff,
      pageLevel: TourFlowPageLevel.topLevel,
      selectedNavigationIndex: 0,
      displayName: 'Check-In Staff',
      email: 'staff@tourflow.com',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ====================================================
          // INTRO
          // ====================================================

          const ModuleCard(
            color: Color(0xFFEEF5FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visitor Check-In / Check-Out',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'Scan a booking QR code or enter its booking code manually.',
                  style: TextStyle(
                    color: TourFlowColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ====================================================
          // CAMERA
          // ====================================================

          Container(
            height: 280,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _cameraOpen
                ? Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _handleQrDetected,
                ),

                Center(
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF22C55E),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: 10,
                  top: 10,
                  child: IconButton.filledTonal(
                    tooltip: 'Close camera',
                    onPressed: controlsDisabled
                        ? null
                        : _closeCamera,
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  ),
                ),
              ],
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 64,
                ),

                const SizedBox(height: 12),

                const Text(
                  'Scan Tourist QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 16),

                FilledButton.icon(
                  key: const Key(
                    'open-qr-camera',
                  ),
                  onPressed: controlsDisabled
                      ? null
                      : _openCamera,
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                  ),
                  label: const Text(
                    'Open Camera',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ====================================================
          // MANUAL BOOKING CODE
          // ====================================================

          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  'Manual Booking Code',
                  subtitle:
                  'Use this when the QR code cannot be scanned.',
                ),

                const SizedBox(height: 14),

                TextField(
                  key: const Key(
                    'manual-booking-code',
                  ),
                  controller: _bookingCodeController,
                  textCapitalization:
                  TextCapitalization.characters,
                  enabled: !controlsDisabled,
                  onSubmitted: (_) {
                    // Verify only.
                    // DO NOT clear input.
                    _verify(
                      updateInput: true,
                    );
                  },
                  decoration: const InputDecoration(
                    labelText: 'Booking code',
                    hintText: 'e.g. TF-ABC123',
                    prefixIcon: Icon(
                      Icons.confirmation_number_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key(
                      'verify-booking',
                    ),
                    onPressed: controlsDisabled
                        ? null
                        : () {
                      // =================================
                      // VERIFY BOOKING
                      //
                      // Keep Booking Code in input.
                      // =================================

                      _verify(
                        updateInput: true,
                      );
                    },
                    icon: _isBusy
                        ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(
                      Icons.search_rounded,
                    ),
                    label: Text(
                      _isBusy
                          ? 'Checking...'
                          : 'Verify Booking',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ====================================================
          // LATEST RESULT
          // ====================================================

          if (_latestResult case final result?) ...[
            const SizedBox(height: 16),

            ModuleCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,

                leading: Icon(
                  _statusIcon(
                    result.status,
                  ),
                  color: _statusColor(
                    result.status,
                  ),
                ),

                title: Text(
                  result.status.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                subtitle: Text(
                  result.bookingCode ??
                      'No matching booking was found.',
                ),

                trailing: TextButton(
                  onPressed: controlsDisabled
                      ? null
                      : () {
                    final lookup =
                        _latestLookupValue ??
                            result.bookingCode;

                    if (lookup == null ||
                        lookup.trim().isEmpty) {
                      return;
                    }

                    // ===============================
                    // VIEW
                    //
                    // Refresh booking details/status,
                    // but NEVER change input field.
                    // ===============================

                    _verify(
                      scannedValue: lookup,
                      updateInput: false,
                    );
                  },
                  child: const Text(
                    'View',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// VERIFICATION SHEET
// ============================================================

class _VerificationSheet extends StatelessWidget {
  const _VerificationSheet({
    required this.result,
    this.onConfirm,
  });

  final StaffBookingVerification result;
  final VoidCallback? onConfirm;

  @override
  Widget build(
      BuildContext context,
      ) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          4,
          24,
          28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _statusIcon(
                result.status,
              ),
              color: _statusColor(
                result.status,
              ),
              size: 48,
            ),

            const SizedBox(height: 10),

            Text(
              result.status.label,
              key: Key(
                'verification-${result.status.name}',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              _statusMessage(
                result.status,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TourFlowColors.muted,
              ),
            ),

            if (result.hasBookingDetails) ...[
              const SizedBox(height: 20),

              _DetailRow(
                'Booking',
                result.bookingCode ?? '-',
              ),

              _DetailRow(
                'Visitor',
                result.visitorName ?? '-',
              ),

              _DetailRow(
                'Party size',
                '${result.visitorCount ?? 0} visitor(s)',
              ),

              _DetailRow(
                'Attraction',
                result.attractionName ?? '-',
              ),

              _DetailRow(
                'Slot',
                _slotLabel(
                  context,
                  result,
                ),
              ),

              if (result.checkedInAt != null)
                _DetailRow(
                  'Check-in',
                  _dateTimeLabel(
                    context,
                    result.checkedInAt!,
                  ),
                ),

              if (result.checkedOutAt != null)
                _DetailRow(
                  'Check-out',
                  _dateTimeLabel(
                    context,
                    result.checkedOutAt!,
                  ),
                ),
            ],

            if (onConfirm != null) ...[
              const SizedBox(height: 20),

              FilledButton.icon(
                key: Key(
                  result.canCheckOut
                      ? 'confirm-check-out'
                      : 'confirm-check-in',
                ),
                onPressed: onConfirm,
                icon: Icon(
                  result.canCheckOut
                      ? Icons.logout_rounded
                      : Icons.how_to_reg_rounded,
                ),
                label: Text(
                  result.canCheckOut
                      ? 'Confirm Check-Out'
                      : 'Confirm Check-In',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DETAIL ROW
// ============================================================

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      this.label,
      this.value,
      );

  final String label;
  final String value;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: TourFlowColors.muted,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STATUS COLOR
// ============================================================

Color _statusColor(
    StaffBookingStatus status,
    ) =>
    switch (status) {
      StaffBookingStatus.valid ||
      StaffBookingStatus.checkedIn ||
      StaffBookingStatus.checkedOut =>
      TourFlowColors.success,

      StaffBookingStatus.wrongSlot ||
      StaffBookingStatus.alreadyUsed =>
      TourFlowColors.warning,

      _ => TourFlowColors.danger,
    };

// ============================================================
// STATUS ICON
// ============================================================

IconData _statusIcon(
    StaffBookingStatus status,
    ) =>
    switch (status) {
      StaffBookingStatus.valid =>
      Icons.verified_rounded,

      StaffBookingStatus.checkedIn =>
      Icons.how_to_reg_rounded,

      StaffBookingStatus.checkedOut =>
      Icons.logout_rounded,

      StaffBookingStatus.alreadyUsed =>
      Icons.task_alt_rounded,

      StaffBookingStatus.wrongAttraction =>
      Icons.wrong_location_rounded,

      StaffBookingStatus.wrongSlot =>
      Icons.schedule_rounded,

      StaffBookingStatus.invalid =>
      Icons.cancel_rounded,
    };

// ============================================================
// STATUS MESSAGE
// ============================================================

String _statusMessage(
    StaffBookingStatus status,
    ) =>
    switch (status) {
      StaffBookingStatus.valid =>
      'This booking is ready for check-in.',

      StaffBookingStatus.invalid =>
      'This booking code is invalid or inactive.',

      StaffBookingStatus.alreadyUsed =>
      'This booking has already been used. Verify it again.',

      StaffBookingStatus.wrongAttraction =>
      'This booking does not belong to your staff organisation.',

      StaffBookingStatus.wrongSlot =>
      'Check-in is unavailable. Check the visit time, '
          'slot status, closures and remaining attraction capacity.',

      StaffBookingStatus.checkedIn =>
      'The visitors are currently checked in. '
          'Confirm check-out when the whole party leaves.',

      StaffBookingStatus.checkedOut =>
      'This visit has already been checked out. '
          'No further check-in or check-out is allowed.',
    };

// ============================================================
// SLOT LABEL
// ============================================================

String _slotLabel(
    BuildContext context,
    StaffBookingVerification verification,
    ) {
  final startsAt = verification.startsAt;
  final endsAt = verification.endsAt;

  if (startsAt == null || endsAt == null) {
    return '-';
  }

  return '${_dateTimeLabel(context, startsAt)} - '
      '${_dateTimeLabel(context, endsAt)}';
}

// ============================================================
// DATE TIME LABEL
// ============================================================

String _dateTimeLabel(
    BuildContext context,
    DateTime value,
    ) {
  final localValue = value.toLocal();

  final localizations =
  MaterialLocalizations.of(context);

  return '${localizations.formatShortDate(localValue)} '
      '${localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(localValue),
  )}';
}