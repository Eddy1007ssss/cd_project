import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/engagement_models.dart';
import '../../repositories/engagement_repository.dart';
import '../../widgets/navigation/navigation_routes.dart';
import '../../widgets/tourflow_widgets.dart';

class StaffQrScannerPage extends StatefulWidget {
  const StaffQrScannerPage({this.gateway, super.key});

  static const String routeName = TourFlowRoutes.staffScan;

  final StaffCheckInGateway? gateway;

  @override
  State<StaffQrScannerPage> createState() => _StaffQrScannerPageState();
}

class _StaffQrScannerPageState extends State<StaffQrScannerPage> {
  final _bookingCodeController = TextEditingController();
  final _scannerController = MobileScannerController(
    autoStart: false,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _cameraOpen = false;
  bool _acceptingScan = false;
  bool _isBusy = false;
  StaffBookingVerification? _latestResult;

  StaffCheckInGateway get _gateway => widget.gateway ?? EngagementRepository();

  @override
  void dispose() {
    _bookingCodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    if (_isBusy) return;
    setState(() {
      _cameraOpen = true;
      _acceptingScan = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted || !_cameraOpen) return;
    try {
      await _scannerController.start();
    } on MobileScannerException catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraOpen = false;
        _acceptingScan = false;
      });
      _showMessage('Unable to open the camera: ${error.errorCode}.');
    }
  }

  Future<void> _closeCamera() async {
    _acceptingScan = false;
    await _scannerController.stop();
    if (mounted) setState(() => _cameraOpen = false);
  }

  Future<void> _handleQrDetected(BarcodeCapture capture) async {
    if (!_acceptingScan || _isBusy || capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue?.trim();
    if (value == null || value.isEmpty) return;
    _acceptingScan = false;
    await _scannerController.stop();
    if (!mounted) return;
    setState(() {
      _cameraOpen = false;
      _bookingCodeController.text = value;
    });
    await _verify(value);
  }

  Future<void> _verify([String? scannedValue]) async {
    FocusScope.of(context).unfocus();
    final lookupValue = (scannedValue ?? _bookingCodeController.text).trim();
    if (lookupValue.isEmpty) {
      final result = StaffBookingVerification.invalid();
      setState(() => _latestResult = result);
      await _showVerification(result);
      return;
    }

    setState(() => _isBusy = true);
    try {
      final result = await _gateway.verifyStaffBooking(lookupValue);
      if (!mounted) return;
      setState(() {
        _latestResult = result;
        _isBusy = false;
      });
      await _showVerification(result);
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to verify this booking. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _confirm(StaffBookingVerification booking) async {
    final bookingId = booking.bookingId;
    if (bookingId == null || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final result = await _gateway.confirmStaffCheckIn(bookingId);
      if (!mounted) return;
      setState(() {
        _latestResult = result;
        _isBusy = false;
      });
      if (result.status == StaffBookingStatus.checkedIn) {
        await _showSuccess(result);
      } else {
        await _showVerification(result);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Check-in could not be completed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _showVerification(StaffBookingVerification result) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _VerificationSheet(
        result: result,
        onConfirm: result.canCheckIn
            ? () {
                Navigator.pop(sheetContext);
                _confirm(result);
              }
            : null,
      ),
    );
  }

  Future<void> _showSuccess(StaffBookingVerification result) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 56,
              color: TourFlowColors.success,
            ),
            const SizedBox(height: 12),
            const Text(
              'Check-In Successful',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${result.visitorName ?? 'Visitor'} has been checked in.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Current visitor count: ${result.currentVisitorCount ?? 0}',
              key: const Key('current-visitor-count'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
          const ModuleCard(
            color: Color(0xFFEEF5FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visitor Check-In',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Scan a booking QR code or enter its booking code manually.',
                  style: TextStyle(color: TourFlowColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: IconButton.filledTonal(
                          tooltip: 'Close camera',
                          onPressed: _closeCamera,
                          icon: const Icon(Icons.close_rounded),
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
                        key: const Key('open-qr-camera'),
                        onPressed: _isBusy ? null : _openCamera,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Open Camera'),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          ModuleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  'Manual Booking Code',
                  subtitle: 'Use this when the QR code cannot be scanned.',
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('manual-booking-code'),
                  controller: _bookingCodeController,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !_isBusy,
                  onSubmitted: (_) => _verify(),
                  decoration: const InputDecoration(
                    labelText: 'Booking code',
                    hintText: 'e.g. TF-ABC123',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('verify-booking'),
                    onPressed: _isBusy ? null : _verify,
                    icon: _isBusy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search_rounded),
                    label: Text(_isBusy ? 'Checking…' : 'Verify Booking'),
                  ),
                ),
              ],
            ),
          ),
          if (_latestResult case final result?) ...[
            const SizedBox(height: 16),
            ModuleCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _statusIcon(result.status),
                  color: _statusColor(result.status),
                ),
                title: Text(
                  result.status.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  result.bookingCode ?? 'No matching booking was found.',
                ),
                trailing: TextButton(
                  onPressed: () => _showVerification(result),
                  child: const Text('View'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VerificationSheet extends StatelessWidget {
  const _VerificationSheet({required this.result, this.onConfirm});

  final StaffBookingVerification result;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _statusIcon(result.status),
              color: _statusColor(result.status),
              size: 48,
            ),
            const SizedBox(height: 10),
            Text(
              result.status.label,
              key: Key('verification-${result.status.name}'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              _statusMessage(result.status),
              textAlign: TextAlign.center,
              style: const TextStyle(color: TourFlowColors.muted),
            ),
            if (result.hasBookingDetails) ...[
              const SizedBox(height: 20),
              _DetailRow('Booking', result.bookingCode ?? '—'),
              _DetailRow('Visitor', result.visitorName ?? '—'),
              _DetailRow(
                'Party size',
                '${result.visitorCount ?? 0} visitor(s)',
              ),
              _DetailRow('Attraction', result.attractionName ?? '—'),
              _DetailRow('Slot', _slotLabel(context, result)),
            ],
            if (onConfirm != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('confirm-check-in'),
                onPressed: onConfirm,
                icon: const Icon(Icons.how_to_reg_rounded),
                label: const Text('Confirm Check-In'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: TourFlowColors.muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

Color _statusColor(StaffBookingStatus status) => switch (status) {
  StaffBookingStatus.valid ||
  StaffBookingStatus.checkedIn => TourFlowColors.success,
  StaffBookingStatus.wrongSlot => TourFlowColors.warning,
  _ => TourFlowColors.danger,
};

IconData _statusIcon(StaffBookingStatus status) => switch (status) {
  StaffBookingStatus.valid => Icons.verified_rounded,
  StaffBookingStatus.checkedIn => Icons.check_circle_rounded,
  StaffBookingStatus.alreadyUsed => Icons.task_alt_rounded,
  StaffBookingStatus.wrongAttraction => Icons.wrong_location_rounded,
  StaffBookingStatus.wrongSlot => Icons.schedule_rounded,
  StaffBookingStatus.invalid => Icons.cancel_rounded,
};

String _statusMessage(StaffBookingStatus status) => switch (status) {
  StaffBookingStatus.valid => 'This booking is ready for check-in.',
  StaffBookingStatus.invalid => 'This booking code is invalid or inactive.',
  StaffBookingStatus.alreadyUsed => 'This booking has already been checked in.',
  StaffBookingStatus.wrongAttraction =>
    'This booking belongs to a different attraction.',
  StaffBookingStatus.wrongSlot =>
    'This booking is outside its permitted check-in window.',
  StaffBookingStatus.checkedIn => 'The visitor was checked in successfully.',
};

String _slotLabel(BuildContext context, StaffBookingVerification verification) {
  final startsAt = verification.startsAt;
  final endsAt = verification.endsAt;
  if (startsAt == null || endsAt == null) return '—';
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatShortDate(startsAt)} '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(startsAt))}–'
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(endsAt))}';
}
