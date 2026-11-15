import 'package:flutter/material.dart';

import '../services/docutrack_service.dart';
import '../ui.dart';

class TrackRequestScreen extends StatelessWidget {
  const TrackRequestScreen({super.key, required this.request});

  final DocumentRequest request;

  static const _steps = [
    'Request Submitted',
    'Verified',
    'Processing',
    'Ready for Claim',
    'Completed',
  ];

  int _currentStep(String status) => switch (status.trim().toLowerCase()) {
    'verified' => 1,
    'processing' => 2,
    'ready for claim' => 3,
    'completed' => 4,
    'rejected' => -1,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const BackHeader(title: 'Track Request'),
          Expanded(
            child: StreamBuilder(
              stream: DocuTrackService.instance.watchRequest(request.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AppAnimatedSwitcher(
                    child: KeyedSubtree(
                      key: const ValueKey('track-error'),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Could not load request status: ${DocuTrackService.formatFirestoreError(snapshot.error!)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.red),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const AppAnimatedSwitcher(
                    child: Center(
                      key: ValueKey('track-loading'),
                      child: AppLoadingIndicator(),
                    ),
                  );
                }
                if (!snapshot.data!.exists) {
                  return const AppAnimatedSwitcher(
                    child: AnimatedEmptyState(
                      key: ValueKey('track-missing'),
                      icon: Icons.search_off_rounded,
                      title: 'Request unavailable',
                      message: 'This request is no longer available.',
                    ),
                  );
                }
                final liveRequest = DocumentRequest.fromSnapshot(
                  snapshot.data!,
                );
                final currentStep = _currentStep(liveRequest.status);
                return AppAnimatedSwitcher(
                  child: KeyedSubtree(
                    key: const ValueKey('track-loaded'),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      children: [
                        const ScreenHeader(
                          title: 'Track your Document',
                          subtitle: 'Follow the progress of your request.',
                        ),
                        const SizedBox(height: 18),
                        WhiteCard(
                          child: Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      liveRequest.documentType,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      liveRequest.reference,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppAnimatedSwitcher(
                                child: KeyedSubtree(
                                  key: ValueKey(liveRequest.status),
                                  child: StatusBadge(liveRequest.status),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const SectionTitle('Request Progress'),
                        const SizedBox(height: 8),
                        if (currentStep < 0)
                          AppAnimatedSwitcher(
                            child: WhiteCard(
                              key: ValueKey(liveRequest.status),
                              child: Text(
                                'This request was rejected. Contact the school office for details.',
                                style: TextStyle(color: AppColors.red),
                              ),
                            ),
                          )
                        else
                          ...List.generate(
                            _steps.length,
                            (index) => _ProgressStep(
                              key: ValueKey(_steps[index]),
                              title: _steps[index],
                              subtitle: index == 0
                                  ? _date(liveRequest.createdAt)
                                  : index < currentStep
                                  ? 'Completed'
                                  : index == currentStep
                                  ? 'Current status'
                                  : 'Not started',
                              done: index < currentStep,
                              active: index == currentStep,
                              last: index == _steps.length - 1,
                            ),
                          ),
                        const SizedBox(height: 10),
                        WhiteCard(
                          child: Text(
                            'Status updates appear here as the school office processes your request.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'View Request Details',
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/request-details',
                            arguments: liveRequest,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  static String _date(DateTime? date) {
    if (date == null) return 'Submitted';
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.active,
    required this.last,
  });

  final String title;
  final String subtitle;
  final bool done;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppColors.green
        : active
        ? AppColors.primary
        : AppColors.border;
    final animationsEnabled = !MediaQuery.disableAnimationsOf(context);
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: animationsEnabled ? 260 : 0),
                  curve: Curves.easeOutCubic,
                  width: active ? 23 : 19,
                  height: active ? 23 : 19,
                  decoration: BoxDecoration(
                    color: done
                        ? AppColors.green
                        : active
                        ? AppColors.primary.withValues(alpha: .12)
                        : AppColors.surface,
                    border: Border.all(color: color, width: active ? 2.5 : 2),
                    shape: BoxShape.circle,
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: .20),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : active
                      ? Center(
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                if (!last)
                  Expanded(
                    child: SizedBox(
                      width: 2,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(color: AppColors.border),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: done ? 1 : 0),
                            duration: Duration(
                              milliseconds: animationsEnabled ? 420 : 0,
                            ),
                            curve: Curves.easeInOutCubic,
                            builder: (context, progress, _) => Align(
                              alignment: Alignment.topCenter,
                              child: FractionallySizedBox(
                                heightFactor: progress,
                                widthFactor: 1,
                                child: const ColoredBox(color: AppColors.green),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.primary : AppColors.text,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppAnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      subtitle,
                      key: ValueKey(subtitle),
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
