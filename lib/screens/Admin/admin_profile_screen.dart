import 'package:flutter/material.dart';

import '../../services/docutrack_service.dart';
import '../../ui.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({
    super.key,
    required this.profile,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final StudentProfile profile;
  final bool isDarkMode;
  final Future<void> Function(bool enabled) onDarkModeChanged;

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late String _name = widget.profile.name;

  @override
  void didUpdateWidget(covariant AdminProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.name != widget.profile.name) {
      _name = widget.profile.name;
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
    children: [
      const ScreenHeader(
        title: 'Admin Profile',
        subtitle: 'Manage your account and app preferences.',
      ),
      const SizedBox(height: 28),
      Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.paleBlue,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .24),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(_name),
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name.isEmpty ? 'Administrator' : _name,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                const StatusBadge('Admin'),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit display name',
            onPressed: _editName,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      const SizedBox(height: 28),
      const _ProfileSectionTitle('Account'),
      const SizedBox(height: 8),
      _ProfileRow(
        icon: Icons.person_outline_rounded,
        label: 'Display name',
        value: _name.isEmpty ? 'Not set' : _name,
      ),
      _ProfileRow(
        icon: Icons.mail_outline_rounded,
        label: 'Email address',
        value: widget.profile.email,
      ),
      _ProfileRow(
        icon: Icons.admin_panel_settings_outlined,
        label: 'Access level',
        value: 'Administrator',
      ),
      _ProfileRow(
        icon: Icons.verified_user_outlined,
        label: 'Account status',
        value: widget.profile.active ? 'Active' : 'Inactive',
        isLast: true,
      ),
      const SizedBox(height: 24),
      const _ProfileSectionTitle('Appearance'),
      const SizedBox(height: 8),
      Material(
        color: Colors.transparent,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 2),
          secondary: Icon(
            widget.isDarkMode
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
            color: AppColors.primary,
          ),
          title: Text(
            'Dark theme',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          subtitle: Text(
            widget.isDarkMode ? 'On' : 'Off',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          value: widget.isDarkMode,
          onChanged: (enabled) async {
            try {
              await widget.onDarkModeChanged(enabled);
            } catch (error) {
              if (context.mounted) _showError(error);
            }
          },
        ),
      ),
      const SizedBox(height: 28),
      OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout_rounded, size: 17),
        label: const Text('Sign out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.red,
          side: BorderSide(color: AppColors.red.withValues(alpha: .45)),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    ],
  );

  Future<void> _editName() async {
    final controller = TextEditingController(text: _name);
    final formKey = GlobalKey<FormState>();
    try {
      final name = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Edit display name'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Display name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your name.'
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, controller.text.trim());
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (name == null || !mounted) return;
      await DocuTrackService.instance.updateOwnAdminName(
        uid: widget.profile.id,
        name: name,
      );
      if (!mounted) return;
      setState(() => _name = name);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Display name updated.')));
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _signOut() async {
    try {
      await DocuTrackService.instance.signOut();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    final initials = parts.take(2).map((part) => part[0].toUpperCase()).join();
    return initials.isEmpty ? 'A' : initials;
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: TextStyle(
      color: AppColors.text,
      fontSize: 15,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: AppColors.muted, size: 19),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      if (!isLast) Divider(height: 1, color: AppColors.border),
    ],
  );
}
