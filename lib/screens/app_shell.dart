import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/docutrack_service.dart';
import '../ui.dart';
import 'dashboard_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'requests_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.profile,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final StudentProfile profile;
  final bool isDarkMode;
  final Future<void> Function(bool enabled) onDarkModeChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        profile: widget.profile,
        onSelectTab: (value) => setState(() => _index = value),
      ),
      RequestsScreen(profile: widget.profile),
      NotificationsScreen(profile: widget.profile),
      ProfileScreen(
        profile: widget.profile,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: AnimatedIndexedStack(index: _index, children: pages),
          ),
        ),
      ),
      bottomNavigationBar: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: DocuTrackService.instance.watchUnreadNotifications(
          widget.profile.id,
        ),
        builder: (context, snapshot) => BottomNavBar(
          index: _index,
          unreadCount: snapshot.data?.docs.length ?? 0,
          onTap: (value) => setState(() => _index = value),
        ),
      ),
    );
  }
}
