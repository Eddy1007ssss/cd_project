import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import 'navigation_routes.dart';

Future<void> signOutAndReturnToSignIn(BuildContext context) async {
  try {
    await AuthRepository().signOut();
  } finally {
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        TourFlowRoutes.signIn,
        (route) => false,
      );
    }
  }
}
