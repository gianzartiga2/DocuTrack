import 'package:flutter/material.dart';

import '../services/docutrack_service.dart';
import '../ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.onDarkModeChanged});

  final Future<void> Function(bool enabled)? onDarkModeChanged;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await DocuTrackService.instance.sendPasswordReset(_email.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Back to sign in',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.text,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: AppColors.border),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    AppThemeToggle(onChanged: widget.onDarkModeChanged),
                  ],
                ),
                const SizedBox(height: 28),
                const Center(child: BrandLogo(size: 72)),
                const SizedBox(height: 26),
                WhiteCard(
                  padding: 24,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.paleBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.mark_email_read_rounded,
                              size: 30,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const ScreenHeader(
                          title: 'Reset your password',
                          subtitle: 'Enter the email linked to your account and we’ll send you a secure reset link.',
                        ),
                        const SizedBox(height: 26),
                        Text(
                          'Email address',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                            hintText: 'you@example.com',
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            return email.contains('@') && email.contains('.')
                                ? null
                                : 'Enter a valid email address.';
                          },
                        ),
                        const SizedBox(height: 18),
                        PrimaryButton(
                          label: _busy ? 'Sending link...' : 'Send reset link',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: _busy ? null : _reset,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 17,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Check your inbox and spam folder for the reset email.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Your account security is important to us.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
