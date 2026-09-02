import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/module3_models.dart';

class BookingQrPage extends StatelessWidget {
  const BookingQrPage({super.key});
  static const routeName = '/booking-qr';
  @override
  Widget build(BuildContext context) {
    final booking = ModalRoute.of(context)?.settings.arguments;
    if (booking is! TourBooking) {
      return const Scaffold(
        body: Center(child: Text('Booking QR is missing.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Booking QR Code')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    booking.slot.attractionName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${shortDate(booking.slot.startsAt)} · ${slotTime(booking.slot)}',
                  ),
                  const SizedBox(height: 22),
                  QrImageView(data: booking.qrToken, size: 230),
                  const SizedBox(height: 12),
                  Text(
                    booking.bookingCode,
                    style: const TextStyle(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Present this code at check-in. Each booking can only be checked in once.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
