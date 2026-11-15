import 'package:flutter/material.dart';

import '../services/docutrack_service.dart';
import '../ui.dart';

class DocumentTypesScreen extends StatelessWidget {
  const DocumentTypesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const BackHeader(title: 'Request Document'),
          Expanded(
            child: StreamBuilder(
              stream: DocuTrackService.instance.watchDocumentTypes(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load documents: ${DocuTrackService.formatFirestoreError(snapshot.error!)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.red),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final types =
                    snapshot.data!.docs.map(DocumentType.fromSnapshot).toList()
                      ..sort(
                        (a, b) => a.name.toLowerCase().compareTo(
                          b.name.toLowerCase(),
                        ),
                      );
                if (types.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'No document types are available right now. Please contact the school office.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    const ScreenHeader(
                      title: 'Select a Document',
                      subtitle:
                          'Choose the document you would like to request.',
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: .75),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates_outlined,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              'Choose a document to see its processing time and submit your request.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...types.map(
                      (type) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/request-form',
                            arguments: type,
                          ),
                          borderRadius: BorderRadius.circular(13),
                          child: WhiteCard(
                            padding: 12,
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.paleBlue,
                                        AppColors.surfaceRaised,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: .12,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.description_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        type.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        type.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 11,
                                          height: 1.35,
                                        ),
                                      ),
                                      Text(
                                        'Processing: ${type.processingDays} working days',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
