import 'package:flutter/material.dart';

import '../services/docutrack_service.dart';
import '../ui.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.profile,
    required this.onSelectTab,
  });

  final StudentProfile profile;
  final ValueChanged<int> onSelectTab;

  static String greetingName(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) return 'STUDENT';
    return trimmedValue.split(RegExp(r'\s+')).first.toUpperCase();
  }

  static String displayName(String value) {
    final trimmedValue = value.trim();
    return trimmedValue.isEmpty ? 'Student' : trimmedValue;
  }

  static String displayStudentId(String value) {
    final trimmedValue = value.trim();
    return trimmedValue.isEmpty ? 'Student ID unavailable' : trimmedValue;
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
    children: [
      Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .16),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(child: BrandLogo(size: 30, showName: false)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DocuTrack',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -.3,
                ),
              ),
              Text(
                'STUDENT PORTAL',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton.filledTonal(
            onPressed: () => onSelectTab(2),
            tooltip: 'Updates',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.text,
              fixedSize: const Size(44, 44),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      const SizedBox(height: 22),
      Text(
        'GOOD DAY, ${DashboardScreen.greetingName(profile.name)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.45,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        'Your campus,\nat a glance.',
        style: TextStyle(
          color: AppColors.text,
          fontSize: 30,
          height: 1.08,
          letterSpacing: -1.1,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 9),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          _InfoPill(
            icon: Icons.person_outline_rounded,
            label: DashboardScreen.displayName(profile.name),
          ),
          _InfoPill(
            icon: Icons.badge_outlined,
            label: DashboardScreen.displayStudentId(profile.studentId),
          ),
        ],
      ),
      const SizedBox(height: 22),
      Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .22),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -38,
              top: -58,
              child: Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: .16),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -15,
              top: -35,
              child: Container(
                width: 122,
                height: 122,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: .12),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.paleBlue,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Need an official document?',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    height: 1.2,
                    letterSpacing: -.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Request it here and follow every step.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 17),
                SizedBox(
                  height: 45,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/documents'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Start a request',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      foregroundColor: AppColors.background,
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 25),
      SectionTitle(
        'Recent Requests',
        action: 'View All',
        onAction: () => onSelectTab(1),
      ),
      StreamBuilder(
        stream: DocuTrackService.instance.watchRequests(
          admin: false,
          uid: profile.id,
          limit: 2,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AppAnimatedSwitcher(
              child: KeyedSubtree(
                key: const ValueKey('dashboard-requests-error'),
                child: _StreamError(
                  error: DocuTrackService.formatFirestoreError(
                    snapshot.error!,
                  ),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const AppAnimatedSwitcher(
              child: Padding(
                key: ValueKey('dashboard-requests-loading'),
                padding: EdgeInsets.all(24),
                child: Center(child: AppLoadingIndicator()),
              ),
            );
          }
          final requests =
              snapshot.data!.docs.map(DocumentRequest.fromSnapshot).toList()
                ..sort(
                  (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                    a.createdAt ?? DateTime(0),
                  ),
                );
          if (requests.isEmpty) {
            return const AppAnimatedSwitcher(
              child: AnimatedEmptyState(
                key: ValueKey('dashboard-requests-empty'),
                icon: Icons.description_outlined,
                title: 'No requests yet',
                message: 'Your requests will appear here after you submit one.',
              ),
            );
          }
          return AppAnimatedSwitcher(
            child: KeyedSubtree(
              key: const ValueKey('dashboard-requests-results'),
              child: Column(
                children: requests.take(2).map((request) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RequestTile(
                      request: request,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/request-details',
                        arguments: request,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 17),
      const SectionTitle('Shortcuts'),
      Row(
        children: [
          _QuickAction(
            icon: Icons.add_circle,
            title: 'Request',
            color: AppColors.primary,
            onTap: () => Navigator.pushNamed(context, '/documents'),
          ),
          _QuickAction(
            icon: Icons.track_changes,
            title: 'My Requests',
            color: AppColors.green,
            onTap: () => onSelectTab(1),
          ),
          _QuickAction(
            icon: Icons.notifications,
            title: 'Alerts',
            color: AppColors.orange,
            onTap: () => onSelectTab(2),
          ),
        ],
      ),
    ],
  );
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request, required this.onTap});

  final DocumentRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(19),
    child: WhiteCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.paleBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.description_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.documentType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.reference,
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          StatusBadge(request.status),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.muted,
            size: 14,
          ),
        ],
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 220),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StreamError extends StatelessWidget {
  const _StreamError({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) => WhiteCard(
    child: Text(
      'Could not load data: $error',
      style: const TextStyle(color: AppColors.red, fontSize: 12),
    ),
  );
}
