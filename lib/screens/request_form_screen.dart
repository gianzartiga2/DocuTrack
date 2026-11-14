import 'package:flutter/material.dart';

import '../services/docutrack_service.dart';
import '../ui.dart';

class RequestFormScreen extends StatefulWidget {
  const RequestFormScreen({super.key, required this.documentType});

  final DocumentType documentType;

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  String? _purpose;
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  int _copies = 1;
  bool _confirmed = false;
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupDate == null || _pickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a preferred pickup date and time.'),
        ),
      );
      return;
    }
    final preferredPickupAt = DateTime(
      _pickupDate!.year,
      _pickupDate!.month,
      _pickupDate!.day,
      _pickupTime!.hour,
      _pickupTime!.minute,
    );
    if (!preferredPickupAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a pickup time in the future.')),
      );
      return;
    }
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm your information before submitting.'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final currentUser = DocuTrackService.instance.currentUser;
      if (currentUser == null) throw Exception('Sign in to submit a request.');
      final profileSnapshot = await DocuTrackService.instance.firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!profileSnapshot.exists) {
        throw Exception('Your student profile could not be found.');
      }
      final profile = StudentProfile.fromSnapshot(profileSnapshot);
      final reference = await DocuTrackService.instance.createRequest(
        student: profile,
        documentType: widget.documentType.name,
        purpose: _purpose!,
        copies: _copies,
        notes: _notes.text,
        preferredPickupAt: preferredPickupAt,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/confirmation',
          arguments: reference,
        );
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

  Future<void> _selectPickupDate() async {
    final tomorrow = DateUtils.dateOnly(DateTime.now())
        .add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: _pickupDate ?? tomorrow,
      firstDate: tomorrow,
      lastDate: tomorrow.add(const Duration(days: 180)),
      helpText: 'Choose a preferred pickup date',
    );
    if (date != null) setState(() => _pickupDate = date);
  }

  Future<void> _selectPickupTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _pickupTime ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Choose a preferred pickup time',
    );
    if (time != null) setState(() => _pickupTime = time);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const BackHeader(title: 'Request Details'),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Text(
                    widget.documentType.name,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 13),
                  WhiteCard(
                    padding: 12,
                    child: Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.documentType.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                widget.documentType.description,
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _Label('Purpose of Request'),
                  DropdownButtonFormField<String>(
                    initialValue: _purpose,
                    decoration: const InputDecoration(
                      hintText: 'Select purpose',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Scholarship',
                        child: Text('Scholarship'),
                      ),
                      DropdownMenuItem(
                        value: 'Employment',
                        child: Text('Employment'),
                      ),
                      DropdownMenuItem(
                        value: 'Personal',
                        child: Text('Personal'),
                      ),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) => setState(() => _purpose = value),
                    validator: (value) => value == null
                        ? 'Select a purpose for this request.'
                        : null,
                  ),
                  const SizedBox(height: 15),
                  const _Label('Number of Copies'),
                  WhiteCard(
                    padding: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _copies > 1
                              ? () => setState(() => _copies--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$_copies',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          onPressed: _copies < 10
                              ? () => setState(() => _copies++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  const _Label('Preferred Pickup Date and Time'),
                  WhiteCard(
                    padding: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : _selectPickupDate,
                                icon: const Icon(Icons.calendar_today_outlined),
                                label: Text(
                                  _pickupDate == null
                                      ? 'Choose date'
                                      : '${_pickupDate!.year}-'
                                            '${_pickupDate!.month.toString().padLeft(2, '0')}-'
                                            '${_pickupDate!.day.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : _selectPickupTime,
                                icon: const Icon(Icons.schedule_outlined),
                                label: Text(
                                  _pickupTime?.format(context) ?? 'Choose time',
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'This is your preferred time, not a confirmed appointment. The office will notify you when your document is ready.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  const _Label('Additional Notes (Optional)'),
                  TextFormField(
                    controller: _notes,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'Enter any additional information',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.paleBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 19,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Estimated processing time: ${widget.documentType.processingDays} working days.',
                            style: TextStyle(
                              color: AppColors.primary,
                              height: 1.4,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _confirmed,
                    onChanged: _busy
                        ? null
                        : (value) =>
                              setState(() => _confirmed = value ?? false),
                    title: Text(
                      'I confirm that the information provided is correct.',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ),
                  PrimaryButton(
                    label: _busy ? 'Submitting...' : 'Submit Request',
                    onPressed: _busy ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: AppColors.text,
      ),
    ),
  );
}
