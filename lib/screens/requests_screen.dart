import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/docutrack_service.dart';
import '../ui.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key, required this.profile});

  final StudentProfile profile;

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  static const _statuses = [
    'All',
    'Pending',
    'Verified',
    'Processing',
    'Ready for Claim',
    'Completed',
    'Rejected',
  ];

  final _search = TextEditingController();
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _olderDocs = [];
  String _statusFilter = 'All';
  bool _hasMore = true;
  bool _loadingMore = false;
  Object? _loadError;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadMore(
    QueryDocumentSnapshot<Map<String, dynamic>> cursor,
  ) async {
    setState(() {
      _loadingMore = true;
      _loadError = null;
    });
    try {
      final page = await DocuTrackService.instance.getRequestPage(
        admin: false,
        uid: widget.profile.id,
        startAfter: cursor,
      );
      if (!mounted) return;
      setState(() {
        final existingIds = _olderDocs.map((doc) => doc.id).toSet();
        _olderDocs.addAll(page.docs.where((doc) => existingIds.add(doc.id)));
        _hasMore = page.docs.length == DocuTrackService.requestPageSize;
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
    children: [
      const ScreenHeader(
        title: 'My Requests',
        subtitle: 'View and track your document requests.',
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search document or reference',
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
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statuses.map((status) {
            final selected = _statusFilter == status;
            return Padding(
              padding: const EdgeInsets.only(right: 7),
              child: ChoiceChip(
                label: Text(status),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) => setState(() => _statusFilter = status),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 12),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: DocuTrackService.instance.watchRequests(
          admin: false,
          uid: widget.profile.id,
          limit: DocuTrackService.requestPageSize,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AppAnimatedSwitcher(
              child: KeyedSubtree(
                key: const ValueKey('requests-error'),
                child: WhiteCard(
                  child: Text(
                    'Could not load your requests: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.red),
                  ),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const AppAnimatedSwitcher(
              child: Padding(
                key: ValueKey('requests-loading'),
                padding: EdgeInsets.all(28),
                child: Center(child: AppLoadingIndicator()),
              ),
            );
          }

          final docsById =
              <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
                for (final doc in _olderDocs) doc.id: doc,
                for (final doc in snapshot.data!.docs) doc.id: doc,
              };
          final requests =
              docsById.values.map(DocumentRequest.fromSnapshot).toList()..sort(
                (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                  a.createdAt ?? DateTime(0),
                ),
              );
          final query = _search.text.trim().toLowerCase();
          final filtered = requests.where((request) {
            final matchesStatus =
                _statusFilter == 'All' || request.status == _statusFilter;
            final matchesSearch =
                query.isEmpty ||
                request.documentType.toLowerCase().contains(query) ||
                request.reference.toLowerCase().contains(query);
            return matchesStatus && matchesSearch;
          }).toList();

          if (requests.isEmpty) {
            return AppAnimatedSwitcher(
              child: const AnimatedEmptyState(
                key: ValueKey('requests-empty'),
                icon: Icons.description_outlined,
                title: 'No requests yet',
                message: 'Your document requests will appear here after you submit one.',
              ),
            );
          }

          return AppAnimatedSwitcher(
            child: KeyedSubtree(
              key: ValueKey(
                filtered.isEmpty
                    ? 'requests-filtered-empty'
                    : 'requests-results',
              ),
              child: Column(
                children: [
                  if (filtered.isEmpty)
                    const AnimatedEmptyState(
                      key: ValueKey('requests-no-match-state'),
                      icon: Icons.search_off_rounded,
                      title: 'No matching requests',
                      message: 'Load older requests to search further back.',
                    )
                  else
                    ...filtered.asMap().entries.map((entry) {
                      final index = entry.key;
                      final request = entry.value;
                      final animationsEnabled = !MediaQuery.disableAnimationsOf(
                        context,
                      );
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(request.id),
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(
                          milliseconds: animationsEnabled
                              ? 260 + (index.clamp(0, 5) * 45)
                              : 0,
                        ),
                        curve: Curves.easeOutCubic,
                        builder: (context, progress, child) => Opacity(
                          opacity: progress,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - progress)),
                            child: child,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/request-details',
                              arguments: request,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            child: WhiteCard(
                              padding: 14,
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.paleBlue,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(
                                          alpha: .10,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.description_rounded,
                                      color: AppColors.primary,
                                      size: 21,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          request.documentType,
                                          style: TextStyle(
                                            color: AppColors.text,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          request.reference,
                                          style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 10,
                                            letterSpacing: .2,
                                          ),
                                        ),
                                        Text(
                                          _dateLabel(request.createdAt),
                                          style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      StatusBadge(request.status),
                                      Icon(
                                        Icons.chevron_right,
                                        color: AppColors.muted,
                                        size: 19,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  if (_loadError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Could not load older requests: $_loadError',
                        style: const TextStyle(color: AppColors.red),
                      ),
                    ),
                  if (_hasMore)
                    OutlinedButton(
                      onPressed: _loadingMore
                          ? null
                          : () => _loadMore(
                              _olderDocs.isEmpty
                                  ? snapshot.data!.docs.last
                                  : _olderDocs.last,
                            ),
                      child: Text(
                        _loadingMore ? 'Loading...' : 'Load older requests',
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Just now';
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
