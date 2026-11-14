import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/docutrack_service.dart';
import '../../ui.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: ScreenHeader(
                    title: 'Students',
                    subtitle: 'Create, update, or deactivate accounts.',
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _editStudent(context),
                  icon: const Icon(Icons.person_add_alt_1, size: 17),
                  label: const Text('Add student'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search name, email, student ID, or program',
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: DocuTrackService.instance.watchStudents(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _AdminError(message: snapshot.error.toString());
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final query = _search.text.trim().toLowerCase();
                      final students =
                          snapshot.data!.docs
                              .map(StudentProfile.fromSnapshot)
                              .where(
                                (student) =>
                                    query.isEmpty ||
                                    student.name.toLowerCase().contains(
                                      query,
                                    ) ||
                                    student.email.toLowerCase().contains(
                                      query,
                                    ) ||
                                    student.studentId.toLowerCase().contains(
                                      query,
                                    ) ||
                                    student.program.toLowerCase().contains(
                                      query,
                                    ),
                              )
                              .toList()
                            ..sort(
                              (a, b) => a.name.toLowerCase().compareTo(
                                b.name.toLowerCase(),
                              ),
                            );
                      if (students.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              query.isEmpty
                                  ? 'No student accounts yet. Add a student to get started.'
                                  : 'No students match "$query".',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: students.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return WhiteCard(
                            padding: 10,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 21,
                                  backgroundColor: student.active
                                      ? AppColors.paleBlue
                                      : AppColors.border,
                                  child: Text(
                                    _initials(student.name),
                                    style: TextStyle(
                                      color: student.active
                                          ? AppColors.primary
                                          : AppColors.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '${student.studentId} • ${student.program}',
                                        style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        student.email,
                                        style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (action) async {
                                    if (action == 'edit') {
                                      await _editStudent(context, student);
                                    } else if (action == 'deactivate') {
                                      await _deactivate(context, student);
                                    } else if (action == 'activate') {
                                      await _setActive(context, student, true);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit student'),
                                    ),
                                    if (student.active)
                                      const PopupMenuItem(
                                        value: 'deactivate',
                                        child: Text('Deactivate account'),
                                      )
                                    else
                                      const PopupMenuItem(
                                        value: 'activate',
                                        child: Text('Reactivate account'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    final initials = parts.take(2).map((part) => part[0].toUpperCase()).join();
    return initials.isEmpty ? '?' : initials;
  }

  Future<void> _editStudent(
    BuildContext context, [
    StudentProfile? student,
  ]) async {
    final result = await showDialog<_StudentFormResult>(
      context: context,
      builder: (_) => _StudentEditor(student: student),
    );
    if (result == null || !context.mounted) return;
    try {
      if (student == null) {
        await DocuTrackService.instance.createStudent(
          name: result.name,
          email: result.email,
          password: result.password,
          studentId: result.studentId,
          program: result.program,
        );
      } else {
        await DocuTrackService.instance.updateStudent(
          StudentProfile(
            id: student.id,
            name: result.name,
            email: student.email,
            studentId: result.studentId,
            program: result.program,
            role: student.role,
            active: student.active,
          ),
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              student == null
                  ? 'Student account created.'
                  : 'Student details updated.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _deactivate(BuildContext context, StudentProfile student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate student?'),
        content: Text(
          '${student.name} will no longer be able to use their account. This can be reversed by an administrator.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep account'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await DocuTrackService.instance.deactivateStudent(student.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student account deactivated.')),
        );
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _setActive(
    BuildContext context,
    StudentProfile student,
    bool active,
  ) async {
    try {
      await DocuTrackService.instance.setStudentActive(student.id, active);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              active
                  ? 'Student account reactivated.'
                  : 'Student account deactivated.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }
}

class _StudentEditor extends StatefulWidget {
  const _StudentEditor({this.student});

  final StudentProfile? student;

  @override
  State<_StudentEditor> createState() => _StudentEditorState();
}

class _StudentEditorState extends State<_StudentEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.student?.name);
  late final _email = TextEditingController(text: widget.student?.email);
  late final _studentId = TextEditingController(
    text: widget.student?.studentId,
  );
  late final _program = TextEditingController(text: widget.student?.program);
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _studentId.dispose();
    _program.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.student == null ? 'Create student' : 'Edit student'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _input(_name, 'Full name'),
              _input(
                _email,
                'Email address',
                enabled: widget.student == null,
                type: TextInputType.emailAddress,
              ),
              _input(_studentId, 'Student ID'),
              _input(_program, 'Program / course'),
              if (widget.student == null)
                _input(
                  _password,
                  'Initial password',
                  obscure: true,
                  helper: 'At least 6 characters; share securely with student.',
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            _StudentFormResult(
              name: _name.text.trim(),
              email: _email.text.trim(),
              studentId: _studentId.text.trim(),
              program: _program.text.trim(),
              password: _password.text,
            ),
          );
        },
        child: Text(widget.student == null ? 'Create account' : 'Save'),
      ),
    ],
  );

  Widget _input(
    TextEditingController controller,
    String label, {
    bool enabled = true,
    bool obscure = false,
    String? helper,
    TextInputType? type,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      keyboardType: type,
      decoration: InputDecoration(labelText: label, helperText: helper),
      validator: (value) {
        if ((value?.trim().isEmpty ?? true)) return '$label is required.';
        if (obscure && (value?.length ?? 0) < 6) {
          return 'Use at least 6 characters.';
        }
        if (type == TextInputType.emailAddress &&
            !(value?.contains('@') ?? false)) {
          return 'Enter a valid email address.';
        }
        return null;
      },
    ),
  );
}

class _StudentFormResult {
  const _StudentFormResult({
    required this.name,
    required this.email,
    required this.studentId,
    required this.program,
    required this.password,
  });

  final String name;
  final String email;
  final String studentId;
  final String program;
  final String password;
}

class _AdminError extends StatelessWidget {
  const _AdminError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Could not load records.\n$message',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.red),
      ),
    ),
  );
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
  );
}
