import 'package:flutter/material.dart';

import '../services/docutrack_service.dart';
import '../ui.dart';

class RequestDetailsScreen extends StatelessWidget {
  const RequestDetailsScreen({super.key, required this.request});

  final DocumentRequest request;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const BackHeader(title: 'Request Details'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.documentType,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            request.reference,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(request.status),
                  ],
                ),
                const SizedBox(height: 16),
                const SectionTitle('Request Information'),
                WhiteCard(
                  child: Column(
                    children: [
                      _DetailLine('Document Type', request.documentType),
                      _DetailLine('Purpose', request.purpose),
                      _DetailLine('Number of Copies', '${request.copies}'),
                      _DetailLine('Reference', request.reference),
                      _DetailLine('Date Submitted', _date(request.createdAt)),
                      if (request.preferredPickupAt != null)
                        _DetailLine(
                          'Preferred Pickup',
                          formatPickupDate(request.preferredPickupAt!),
                        ),
                    ],
                  ),
                ),
                if (request.status == 'Ready for Claim' &&
                    request.preferredPickupAt != null) ...[
                  const SizedBox(height: 12),
                  WhiteCard(
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.green,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pickup reminder: your preferred time is ${formatPickupDate(request.preferredPickupAt!)}.',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Current Status',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.paleBlue,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.radio_button_checked,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          request.status,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (request.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Additional Notes',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  WhiteCard(child: Text(request.notes)),
                ],
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Track Request',
                  icon: Icons.track_changes,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/track',
                    arguments: request,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  String _date(DateTime? date) {
    if (date == null) return 'Pending';
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
