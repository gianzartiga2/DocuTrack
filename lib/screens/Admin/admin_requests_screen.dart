import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/docutrack_service.dart';
import '../../ui.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
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

  static const _statuses = [
    'Pending',
    'Verified',
    'Processing',
    'Ready for Claim',
    'Completed',
    'Rejected',
  ];

  Future<void> _loadMore(
    QueryDocumentSnapshot<Map<String, dynamic>> cursor,
  ) async {
    setState(() {
      _loadingMore = true;
      _loadError = null;
    });
    try {
      final page = await DocuTrackService.instance.getRequestPage(
        admin: true,
        uid: '',
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
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
            child: Row(
              children: [
                const Expanded(
                  child: ScreenHeader(
                    title: 'Requests',
                    subtitle: 'Create, review, and update requests.',
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _create(context),
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('New request'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search student, document, or reference',
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
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', ..._statuses].map((status) {
                            final selected = _statusFilter == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 7),
                              child: ChoiceChip(
                                label: Text(status),
                                selected: selected,
                                showCheckmark: false,
                                onSelected: (_) =>
                                    setState(() => _statusFilter = status),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: DocuTrackService.instance.watchRequests(
                      admin: true,
                      uid: '',
                      limit: DocuTrackService.requestPageSize,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return AppAnimatedSwitcher(
                          child: KeyedSubtree(
                            key: const ValueKey('admin-requests-error'),
                            child: _ErrorView(
                              message: snapshot.error.toString(),
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const AppAnimatedSwitcher(
                          child: Center(
                            key: ValueKey('admin-requests-loading'),
                            child: AppLoadingIndicator(),
                          ),
                        );
                      }
                      final query = _search.text.trim().toLowerCase();
                      final docsById =
                          <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
                            for (final doc in _olderDocs) doc.id: doc,
                            for (final doc in snapshot.data!.docs) doc.id: doc,
                          };
                      final allRequests =
                          docsById.values
                              .map(DocumentRequest.fromSnapshot)
                              .toList()
                            ..sort(
                              (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                                a.createdAt ?? DateTime(0),
                              ),
                            );
                      final requests =
                          allRequests
                              .where(
                                (request) =>
                                    (_statusFilter == 'All' ||
                                        request.status == _statusFilter) &&
                                    (query.isEmpty ||
                                        request.studentName
                                            .toLowerCase()
                                            .contains(query) ||
                                        request.studentEmail
                                            .toLowerCase()
                                            .contains(query) ||
                                        request.reference
                                            .toLowerCase()
                                            .contains(query) ||
                                        request.documentType
                                            .toLowerCase()
                                            .contains(query)),
                              )
                              .toList()
                            ..sort(
                              (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                                a.createdAt ?? DateTime(0),
                              ),
                            );
                      return AppAnimatedSwitcher(
                        child: ListView.separated(
                          key: ValueKey(
                            requests.isEmpty
                                ? 'admin-requests-empty'
                                : 'admin-requests-results',
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount:
                              (requests.isEmpty ? 1 : requests.length) + 1,
                          separatorBuilder: (_, _) => const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            if (requests.isEmpty) {
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  child: AnimatedEmptyState(
                                    icon:
                                        query.isEmpty && _statusFilter == 'All'
                                        ? Icons.inbox_outlined
                                        : Icons.search_off_rounded,
                                    title:
                                        query.isEmpty && _statusFilter == 'All'
                                        ? 'No requests yet'
                                        : 'No matching requests',
                                    message:
                                        query.isEmpty && _statusFilter == 'All'
                                        ? 'Student requests will appear here.'
                                        : 'Load older requests to search further back.',
                                  ),
                                );
                              }
                              return _paginationFooter(snapshot.data!.docs);
                            }
                            if (index == requests.length) {
                              return _paginationFooter(snapshot.data!.docs);
                            }
                            final request = requests[index];
                            final animationsEnabled =
                                !MediaQuery.disableAnimationsOf(context);
                            return TweenAnimationBuilder<double>(
                              key: ValueKey(request.id),
                              tween: Tween(begin: 0, end: 1),
                              duration: Duration(
                                milliseconds: animationsEnabled
                                    ? 360 + (index.clamp(0, 6).toInt() * 55)
                                    : 0,
                              ),
                              curve: Curves.easeOutCubic,
                              builder: (context, progress, child) => Opacity(
                                opacity: progress,
                                child: Transform.translate(
                                  offset: Offset(0, 18 * (1 - progress)),
                                  child: child,
                                ),
                              ),
                              child: WhiteCard(
                                padding: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: AppColors.paleBlue,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.description_outlined,
                                            color: AppColors.primary,
                                            size: 19,
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
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
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
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        StatusBadge(request.status),
                                        PopupMenuButton<String>(
                                          tooltip: 'Request actions',
                                          onSelected: (action) async {
                                            if (action == 'status') {
                                              await _changeStatus(
                                                context,
                                                request,
                                              );
                                            } else if (action == 'delete') {
                                              await _delete(context, request);
                                            }
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                              value: 'status',
                                              child: Text('Update status'),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Delete request'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          color: AppColors.muted,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            request.studentName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.text,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 20),
                                      child: Text(
                                        request.studentEmail,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${request.purpose} • ${request.copies} copy/copies',
                                            style: TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (request.preferredPickupAt != null) ...[
                                      const SizedBox(height: 7),
                                      Text(
                                        'Preferred pickup: ${formatPickupDate(request.preferredPickupAt!)}',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    if (request.notes.isNotEmpty) ...[
                                      const SizedBox(height: 7),
                                      Text(
                                        'Notes: ${request.notes}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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

  Widget _paginationFooter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> firstPage,
  ) {
    final cursor = _olderDocs.isEmpty
        ? (firstPage.isEmpty ? null : firstPage.last)
        : _olderDocs.last;
    return Column(
      children: [
        if (_loadError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Could not load older requests: $_loadError',
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        if (_hasMore && cursor != null)
          OutlinedButton(
            onPressed: _loadingMore ? null : () => _loadMore(cursor),
            child: Text(_loadingMore ? 'Loading...' : 'Load older requests'),
          ),
      ],
    );
  }

  Future<void> _create(BuildContext context) async {
    final result = await showDialog<_NewRequestData>(
      context: context,
      builder: (_) => const _NewRequestDialog(),
    );
    if (result == null || !context.mounted) return;
    try {
      final reference = await DocuTrackService.instance.createRequest(
        student: result.student,
        documentType: result.documentType.name,
        purpose: result.purpose,
        copies: result.copies,
        notes: result.notes,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Request created: $reference')));
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _changeStatus(
    BuildContext context,
    DocumentRequest request,
  ) async {
    final status = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Update request status'),
        children: _statuses
            .map(
              (status) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, status),
                child: Row(
                  children: [
                    if (status == request.status)
                      Icon(Icons.check, color: AppColors.primary, size: 18)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(status),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (status == null) return;
    try {
      await DocuTrackService.instance.updateRequestStatus(request, status);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _delete(BuildContext context, DocumentRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete request?'),
        content: Text(
          'Delete request ${request.reference}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await DocuTrackService.instance.deleteRequest(request.id);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }
}

class _NewRequestDialog extends StatefulWidget {
  const _NewRequestDialog();

  @override
  State<_NewRequestDialog> createState() => _NewRequestDialogState();
}

class _NewRequestDialogState extends State<_NewRequestDialog> {
  StudentProfile? _student;
  DocumentType? _documentType;
  String? _purpose;
  int _copies = 1;
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create request'),
    content: SizedBox(
      width: 440,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: DocuTrackService.instance.watchStudents(),
        builder: (context, studentSnapshot) {
          if (studentSnapshot.hasError) {
            return Text('Could not load students: ${studentSnapshot.error}');
          }
          if (!studentSnapshot.hasData) {
            return const SizedBox(
              height: 90,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final students = studentSnapshot.data!.docs
              .map(StudentProfile.fromSnapshot)
              .where((student) => student.active)
              .toList();
          if (students.isEmpty) {
            return const Text('Create an active student account first.');
          }
          _student ??= students.first;
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: DocuTrackService.instance.watchDocumentTypes(),
            builder: (context, documentSnapshot) {
              if (documentSnapshot.hasError) {
                return Text(
                  'Could not load document types: ${documentSnapshot.error}',
                );
              }
              if (!documentSnapshot.hasData) {
                return const SizedBox(
                  height: 90,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final types = documentSnapshot.data!.docs
                  .map(DocumentType.fromSnapshot)
                  .toList();
              if (types.isEmpty) {
                return const Text('Add an active document type first.');
              }
              _documentType ??= types.first;
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: students.any((s) => s.id == _student!.id)
                          ? _student!.id
                          : null,
                      decoration: const InputDecoration(labelText: 'Student'),
                      items: students
                          .map(
                            (student) => DropdownMenuItem(
                              value: student.id,
                              child: Text(
                                '${student.name} (${student.studentId})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) => setState(
                        () => _student = students
                            .where((student) => student.id == id)
                            .firstOrNull,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue:
                          types.any((type) => type.id == _documentType!.id)
                          ? _documentType!.id
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Document type',
                      ),
                      items: types
                          .map(
                            (type) => DropdownMenuItem(
                              value: type.id,
                              child: Text(type.name),
                            ),
                          )
                          .toList(),
                      onChanged: (id) => setState(
                        () => _documentType = types
                            .where((type) => type.id == id)
                            .firstOrNull,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _purpose,
                      decoration: const InputDecoration(labelText: 'Purpose'),
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
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _notes,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                      maxLength: 500,
                    ),
                    Row(
                      children: [
                        const Text('Copies'),
                        const Spacer(),
                        IconButton(
                          onPressed: _copies > 1
                              ? () => setState(() => _copies--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$_copies'),
                        IconButton(
                          onPressed: _copies < 10
                              ? () => setState(() => _copies++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
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
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _student == null || _documentType == null || _purpose == null
            ? null
            : () => Navigator.pop(
                context,
                _NewRequestData(
                  student: _student!,
                  documentType: _documentType!,
                  purpose: _purpose!,
                  copies: _copies,
                  notes: _notes.text,
                ),
              ),
        child: const Text('Create'),
      ),
    ],
  );
}

class _NewRequestData {
  const _NewRequestData({
    required this.student,
    required this.documentType,
    required this.purpose,
    required this.copies,
    required this.notes,
  });

  final StudentProfile student;
  final DocumentType documentType;
  final String purpose;
  final int copies;
  final String notes;
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Could not load requests.\n$message',
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
