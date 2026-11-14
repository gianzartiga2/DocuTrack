import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/docutrack_service.dart';
import '../../ui.dart';

class AdminDocumentsScreen extends StatefulWidget {
  const AdminDocumentsScreen({super.key});

  @override
  State<AdminDocumentsScreen> createState() => _AdminDocumentsScreenState();
}

class _AdminDocumentsScreenState extends State<AdminDocumentsScreen> {
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
                    title: 'Document Types',
                    subtitle: 'Manage the documents students can request.',
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Document type actions',
                  icon: const Icon(Icons.add_circle),
                  onSelected: (action) {
                    if (action == 'add') {
                      _edit(context);
                    } else {
                      _addStandardTypes(context);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'add',
                      child: ListTile(
                        leading: Icon(Icons.add),
                        title: Text('Add a document type'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'standard',
                      child: ListTile(
                        leading: Icon(Icons.library_add_outlined),
                        title: Text('Add standard document types'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
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
                      hintText: 'Search document types',
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
                    stream: DocuTrackService.instance.watchDocumentTypes(
                      includeInactive: true,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _ErrorView(message: snapshot.error.toString());
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final query = _search.text.trim().toLowerCase();
                      final types =
                          snapshot.data!.docs
                              .map(DocumentType.fromSnapshot)
                              .where(
                                (type) =>
                                    query.isEmpty ||
                                    type.name.toLowerCase().contains(query) ||
                                    type.description.toLowerCase().contains(
                                      query,
                                    ),
                              )
                              .toList()
                            ..sort(
                              (a, b) => a.name.toLowerCase().compareTo(
                                b.name.toLowerCase(),
                              ),
                            );
                      if (types.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              query.isEmpty
                                  ? 'No document types yet. Add one for students to request.'
                                  : 'No document types match "$query".',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: types.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final type = types[index];
                          return WhiteCard(
                            padding: 12,
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.paleBlue,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Icon(
                                    Icons.description_rounded,
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
                                        type.name,
                                        style: TextStyle(
                                          color: AppColors.text,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '${type.description} • ${type.processingDays} working days',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 11,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(
                                  type.active ? 'Active' : 'Inactive',
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (action) async {
                                    if (action == 'edit') {
                                      await _edit(context, type);
                                    } else {
                                      await _delete(context, type);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
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

  Future<void> _edit(BuildContext context, [DocumentType? type]) async {
    final result = await showDialog<_DocumentForm>(
      context: context,
      builder: (_) => _DocumentEditor(type: type),
    );
    if (result == null || !context.mounted) return;
    try {
      await DocuTrackService.instance.saveDocumentType(
        id: type?.id,
        name: result.name,
        description: result.description,
        processingDays: result.days,
        active: result.active,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type == null ? 'Document type added.' : 'Document type updated.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _addStandardTypes(BuildContext context) async {
    try {
      final added = await DocuTrackService.instance.addStandardDocumentTypes();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? 'All standard document types are already in your catalog.'
                : '$added standard document types added.',
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _delete(BuildContext context, DocumentType type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete document type?'),
        content: Text(
          'Students will no longer be able to request ${type.name}.',
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
      await DocuTrackService.instance.deleteDocumentType(type.id);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }
}

class _DocumentEditor extends StatefulWidget {
  const _DocumentEditor({this.type});

  final DocumentType? type;

  @override
  State<_DocumentEditor> createState() => _DocumentEditorState();
}

class _DocumentEditorState extends State<_DocumentEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.type?.name);
  late final _description = TextEditingController(
    text: widget.type?.description,
  );
  late final _days = TextEditingController(
    text: (widget.type?.processingDays ?? 3).toString(),
  );
  late bool _active = widget.type?.active ?? true;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.type == null ? 'Add document type' : 'Edit document type',
    ),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _input(_name, 'Name'),
            _input(_description, 'Description'),
            TextFormField(
              controller: _days,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Processing days'),
              validator: (value) {
                final days = int.tryParse(value ?? '');
                return days == null || days < 1 || days > 90
                    ? 'Enter a number from 1 to 90.'
                    : null;
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available to students'),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
          ],
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
            _DocumentForm(
              name: _name.text.trim(),
              description: _description.text.trim(),
              days: int.parse(_days.text),
              active: _active,
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );

  Widget _input(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value?.trim().isEmpty ?? true ? '$label is required.' : null,
    ),
  );
}

class _DocumentForm {
  const _DocumentForm({
    required this.name,
    required this.description,
    required this.days,
    required this.active,
  });

  final String name;
  final String description;
  final int days;
  final bool active;
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Could not load document types.\n$message',
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
