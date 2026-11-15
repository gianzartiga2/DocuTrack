import 'package:flutter/material.dart';

import '../services/docutrack_service.dart';
import '../ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.onDarkModeChanged});

  final Future<void> Function(bool enabled)? onDarkModeChanged;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _studentId = TextEditingController();
  final _program = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _hidePassword = true;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _studentId.dispose();
    _program.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await DocuTrackService.instance.registerStudent(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        studentId: _studentId.text,
        program: _program.text,
      );
      await DocuTrackService.instance.signIn(_email.text, _password.text);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
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
          padding: const EdgeInsets.all(26),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.fromLTRB(23, 18, 23, 23),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: .8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .22),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Back',
                          icon: const Icon(Icons.arrow_back),
                        ),
                        AppThemeToggle(onChanged: widget.onDarkModeChanged),
                      ],
                    ),
                    const Center(child: BrandLogo(size: 68)),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Create Student Account',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Center(
                      child: Text(
                        'Your account will be registered as a student.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _field(
                      'Full Name',
                      _name,
                      'Enter your full name',
                      Icons.person_outline,
                    ),
                    _field(
                      'Email Address',
                      _email,
                      'Enter your email address',
                      Icons.mail_outline,
                      type: TextInputType.emailAddress,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        return email.contains('@') && email.contains('.')
                            ? null
                            : 'Enter a valid email address.';
                      },
                    ),
                    _field(
                      'Student ID',
                      _studentId,
                      'Enter your student ID',
                      Icons.badge_outlined,
                    ),
                    _field(
                      'Program / Course',
                      _program,
                      'Enter your program or course',
                      Icons.school_outlined,
                    ),
                    _passwordField(
                      'Password',
                      _password,
                      'At least 6 characters',
                    ),
                    _passwordField(
                      'Confirm Password',
                      _confirmPassword,
                      'Re-enter your password',
                      confirm: true,
                    ),
                    PrimaryButton(
                      label: _busy ? 'Creating account...' : 'Create Account',
                      onPressed: _busy ? null : _register,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? type,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: type,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18),
            hintText: hint,
          ),
          validator:
              validator ??
              (value) => (value?.trim().isEmpty ?? true)
                  ? '$label is required.'
                  : null,
        ),
      ],
    ),
  );

  Widget _passwordField(
    String label,
    TextEditingController controller,
    String hint, {
    bool confirm = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: _hidePassword,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, size: 18),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
              ),
            ),
            hintText: hint,
          ),
          validator: (value) {
            if (value == null || value.length < 6) {
              return 'Password must be at least 6 characters.';
            }
            if (confirm && value != _password.text) {
              return 'Passwords do not match.';
            }
            return null;
          },
        ),
      ],
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
  );
}
