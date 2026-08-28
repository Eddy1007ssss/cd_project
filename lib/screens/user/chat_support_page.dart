import 'package:flutter/material.dart';

import '../../widgets/navigation/user_bottom_navigation_bar.dart';
import '../../widgets/navigation/user_sidebar.dart';

/// Static placeholder until the chatbot pages in Module 6 are built.
class ChatSupportPage extends StatelessWidget {
  const ChatSupportPage({super.key});

  static const routeName = '/user/chat';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      drawer: UserSidebar(
        displayName: 'Alex Tan',
        email: 'alex@example.com',
        selectedIndex: 3,
        onLogout: () => Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false),
      ),
      appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, title: const Text('Chatbot & Support')),
      body: const Center(child: Text('Tourist support will be available when Module 6 is completed.')),
      bottomNavigationBar: const UserBottomNavigationBar(selectedIndex: 3),
    );
  }
}
