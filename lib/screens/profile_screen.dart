import 'package:flutter/material.dart';

import 'account_support_screens.dart';
import '../services/docutrack_service.dart';
import '../ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final StudentProfile profile;
  final bool isDarkMode;
  final Future<void> Function(bool enabled) onDarkModeChanged;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
    children: [
      const ScreenHeader(title: 'Profile'),
      const SizedBox(height: 18),
      WhiteCard(
        padding: 17,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.paleBlue, AppColors.surfaceRaised],
                ),
              ),
              child: Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    profile.email,
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                  Text(
                    '${profile.studentId} • ${profile.program}',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  const StatusBadge('Student'),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      _ProfileGroup(
        title: 'Account',
        items: [
          _ProfileItem(
            Icons.person_outline,
            'Personal Information',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => PersonalInformationScreen(profile: profile),
              ),
            ),
          ),
          _ProfileItem(
            Icons.lock_outline,
            'Change Password',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const ChangePasswordScreen(),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _ProfileGroup(
        title: 'Support',
        items: [
          _ProfileItem(
            Icons.help_outline,
            'Help & Support',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const HelpSupportScreen(),
              ),
            ),
          ),
          _ProfileItem(
            Icons.info_outline,
            'About DocuTrack',
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AboutDocuTrackScreen(),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _AppearanceGroup(isDarkMode: isDarkMode, onChanged: onDarkModeChanged),
      const SizedBox(height: 18),
      OutlinedButton.icon(
        onPressed: () async {
          try {
            await DocuTrackService.instance.signOut();
          } catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(error.toString())));
            }
          }
        },
        icon: const Icon(Icons.logout, size: 17),
        label: const Text('Log Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.red,
          side: const BorderSide(color: AppColors.red),
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    ],
  );
}

class _ProfileItem {
  const _ProfileItem(this.icon, this.title, this.onTap);
  final IconData icon;
  final String title;
  final VoidCallback onTap;
}

class _ProfileGroup extends StatelessWidget {
  const _ProfileGroup({required this.title, required this.items});
  final String title;
  final List<_ProfileItem> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      const SizedBox(height: 8),
      WhiteCard(
        padding: 2,
        child: Column(
          children: items
              .map(
                (item) => Material(
                  color: Colors.transparent,
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      item.icon,
                      color: AppColors.primary,
                      size: 19,
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.muted,
                      size: 18,
                    ),
                    onTap: item.onTap,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    ],
  );
}

class _AppearanceGroup extends StatelessWidget {
  const _AppearanceGroup({required this.isDarkMode, required this.onChanged});

  final bool isDarkMode;
  final Future<void> Function(bool enabled) onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Appearance',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      const SizedBox(height: 8),
      WhiteCard(
        padding: 2,
        child: Material(
          color: Colors.transparent,
          child: SwitchListTile(
            secondary: Icon(
              isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: AppColors.primary,
              size: 19,
            ),
            title: const Text(
              'Dark theme',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              isDarkMode ? 'On' : 'Off',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            value: isDarkMode,
            onChanged: (enabled) async {
              try {
                await onChanged(enabled);
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ),
      ),
    ],
  );
}
