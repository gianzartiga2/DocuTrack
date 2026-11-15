import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/docutrack_service.dart';
import '../ui.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
    children: [
      Row(
        children: [
          const Expanded(
            child: ScreenHeader(
              title: 'Updates',
              subtitle: 'Status changes for your document requests.',
            ),
          ),
          TextButton(
            onPressed: () => _markAllRead(context),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: DocuTrackService.instance.watchNotifications(profile.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AppAnimatedSwitcher(
              child: KeyedSubtree(
                key: const ValueKey('notifications-error'),
                child: WhiteCard(
                  child: Text(
                    'Could not load updates: ${DocuTrackService.formatFirestoreError(snapshot.error!)}',
                    style: const TextStyle(color: AppColors.red),
                  ),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const AppAnimatedSwitcher(
              child: Center(
                key: ValueKey('notifications-loading'),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: AppLoadingIndicator(),
                ),
              ),
            );
          }
          final notifications = snapshot.data!.docs
              .map(StudentNotification.fromSnapshot)
              .toList();
          if (notifications.isEmpty) {
            return const AppAnimatedSwitcher(
              child: AnimatedEmptyState(
                key: ValueKey('notifications-empty'),
                icon: Icons.notifications_none_rounded,
                title: 'No updates yet',
                message: 'You’ll see an update here when you submit a request or its status changes.',
              ),
            );
          }
          return AppAnimatedSwitcher(
            child: KeyedSubtree(
              key: const ValueKey('notifications-results'),
              child: Column(
                children: notifications
                    .map(
                      (notification) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _NotificationCard(
                          notification: notification,
                          onTap: notification.isRead
                              ? null
                              : () => _markRead(context, notification),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    ],
  );

  Future<void> _markRead(
    BuildContext context,
    StudentNotification notification,
  ) async {
    try {
      await DocuTrackService.instance.markNotificationRead(
        profile.id,
        notification.id,
      );
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _markAllRead(BuildContext context) async {
    try {
      await DocuTrackService.instance.markAllNotificationsRead(profile.id);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final StudentNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = notification.status.trim().toLowerCase();
    final color = switch (normalizedStatus) {
      'ready for claim' || 'completed' => AppColors.green,
      'rejected' => AppColors.red,
      'processing' || 'verified' => AppColors.primary,
      _ => AppColors.orange,
    };
    return WhiteCard(
      padding: 12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notification.type == 'request_received'
                      ? Icons.mark_email_unread_outlined
                      : Icons.notifications_active_outlined,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: AppColors.text,
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${notification.documentType} • ${notification.reference}',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                    if (notification.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(notification.createdAt!),
                        style: TextStyle(color: AppColors.muted, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${local.day}/${local.month}/${local.year} • $hour:$minute $period';
  }
}
