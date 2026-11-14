import 'package:flutter/material.dart';

import '../services/docutrack_service.dart';
import '../ui.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key, required this.profile});

  final StudentProfile profile;

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.name);
  late final _studentId = TextEditingController(text: widget.profile.studentId);
  late final _program = TextEditingController(text: widget.profile.program);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _studentId.dispose();
    _program.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await DocuTrackService.instance.updateOwnStudentProfile(
        uid: widget.profile.id,
        name: _name.text,
        studentId: _studentId.text,
        program: _program.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personal information updated.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: BackHeader(title: 'Personal Information'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                const ScreenHeader(
                  title: 'Your details',
                  subtitle: 'Keep your student information up to date.',
                ),
                const SizedBox(height: 18),
                WhiteCard(
                  padding: 18,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FormLabel('Full name'),
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person_outline_rounded),
                            hintText: 'Enter your full name',
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 16),
                        const _FormLabel('Email address'),
                        TextFormField(
                          initialValue: widget.profile.email,
                          readOnly: true,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                            helperText: 'Email changes require verification. Contact your school office for help.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _FormLabel('Student ID'),
                        TextFormField(
                          controller: _studentId,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.badge_outlined),
                            hintText: 'Enter your student ID',
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 16),
                        const _FormLabel('Program / course'),
                        TextFormField(
                          controller: _program,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.school_outlined),
                            hintText: 'Enter your program or course',
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 22),
                        PrimaryButton(
                          label: _busy ? 'Saving changes...' : 'Save changes',
                          icon: Icons.check_rounded,
                          onPressed: _busy ? null : _save,
                        ),
                      ],
                    ),
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

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _hidePasswords = true;
  bool _busy = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await DocuTrackService.instance.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Use at least 6 characters.';
    }
    if (value == _currentPassword.text) {
      return 'Choose a password different from your current one.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: BackHeader(title: 'Change Password'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                const ScreenHeader(
                  title: 'Secure your account',
                  subtitle:
                      'Confirm your current password, then choose a new one.',
                ),
                const SizedBox(height: 18),
                WhiteCard(
                  padding: 18,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FormLabel('Current password'),
                        TextFormField(
                          controller: _currentPassword,
                          obscureText: _hidePasswords,
                          autofillHints: const [AutofillHints.password],
                          decoration: _passwordDecoration(
                            'Enter your current password',
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter your current password.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        const _FormLabel('New password'),
                        TextFormField(
                          controller: _newPassword,
                          obscureText: _hidePasswords,
                          decoration: _passwordDecoration(
                            'At least 6 characters',
                          ),
                          validator: _validateNewPassword,
                        ),
                        const SizedBox(height: 16),
                        const _FormLabel('Confirm new password'),
                        TextFormField(
                          controller: _confirmPassword,
                          obscureText: _hidePasswords,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              _busy ? null : _changePassword(),
                          decoration: _passwordDecoration(
                            'Enter your new password again',
                          ),
                          validator: (value) {
                            if (value != _newPassword.text) {
                              return 'Passwords do not match.';
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => setState(
                              () => _hidePasswords = !_hidePasswords,
                            ),
                            icon: Icon(
                              _hidePasswords
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 17,
                            ),
                            label: Text(
                              _hidePasswords
                                  ? 'Show passwords'
                                  : 'Hide passwords',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          label: _busy
                              ? 'Updating password...'
                              : 'Update password',
                          icon: Icons.lock_reset_rounded,
                          onPressed: _busy ? null : _changePassword,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  InputDecoration _passwordDecoration(String hint) => InputDecoration(
    prefixIcon: const Icon(Icons.lock_outline_rounded),
    suffixIcon: IconButton(
      tooltip: _hidePasswords ? 'Show password' : 'Hide password',
      onPressed: () => setState(() => _hidePasswords = !_hidePasswords),
      icon: Icon(
        _hidePasswords
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
      ),
    ),
    hintText: hint,
  );
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _helpItems = [
    (
      question: 'How do I request a document?',
      answer: 'From Home, choose Start a request. Select the document, enter its purpose and any notes, confirm your information, then submit.',
    ),
    (
      question: 'Where can I check my request status?',
      answer: 'Open Requests to see your submitted documents. Select a request and choose Track Request to view its current progress.',
    ),
    (
      question: 'How do I change my password?',
      answer: 'Open Profile, choose Change Password, enter your current password, and set a new password. If you cannot sign in, use Forgot Password on the sign-in screen.',
    ),
    (
      question: 'Who can help with a delayed or incorrect request?',
      answer: 'Contact your school registrar or student services office and include the request reference number so they can find it.',
    ),
    (
      question: 'Can I change my email address here?',
      answer: 'Email addresses are tied to your sign-in and cannot be edited in the profile form. Contact your school office for assistance.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: BackHeader(title: 'Help & Support'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                const ScreenHeader(
                  title: 'How can we help?',
                  subtitle:
                      'Find quick answers to common questions about DocuTrack.',
                ),
                const SizedBox(height: 18),
                WhiteCard(
                  padding: 4,
                  child: Column(
                    children: _helpItems
                        .map(
                          (item) => Material(
                            color: AppColors.surface,
                            child: ExpansionTile(
                              leading: Icon(
                                Icons.help_outline_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              title: Text(
                                item.question,
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                16,
                              ),
                              expandedCrossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.answer,
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                WhiteCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Still need help?',
                              style: TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Contact your school registrar or student services office. For request questions, include your reference number.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class AboutDocuTrackScreen extends StatelessWidget {
  const AboutDocuTrackScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: BackHeader(title: 'About DocuTrack'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                WhiteCard(
                  padding: 24,
                  child: Column(
                    children: [
                      const BrandLogo(size: 82),
                      const SizedBox(height: 22),
                      Text(
                        'DocuTrack',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Student Document Portal',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paleBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'A simple place to request school documents, keep track of their progress, and stay informed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What you can do',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 14),
                      _AboutFeature(
                        icon: Icons.description_outlined,
                        text: 'Submit document requests online',
                      ),
                      SizedBox(height: 12),
                      _AboutFeature(
                        icon: Icons.track_changes_rounded,
                        text: 'Follow request status updates',
                      ),
                      SizedBox(height: 12),
                      _AboutFeature(
                        icon: Icons.notifications_none_rounded,
                        text: 'Keep your requests together in one place',
                      ),
                    ],
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

class _AboutFeature extends StatelessWidget {
  const _AboutFeature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.primary, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
    ],
  );
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: TextStyle(
        color: AppColors.text,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

String? _required(String? value) =>
    value?.trim().isNotEmpty == true ? null : 'This field is required.';

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
  );
}
