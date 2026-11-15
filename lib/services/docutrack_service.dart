import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

@immutable
class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.program,
    required this.role,
    required this.active,
  });

  final String id;
  final String name;
  final String email;
  final String studentId;
  final String program;
  final String role;
  final bool active;

  factory StudentProfile.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return StudentProfile(
      id: snapshot.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      program: data['program'] as String? ?? '',
      role: data['role'] as String? ?? '',
      active: data['active'] as bool? ?? false,
    );
  }

  Map<String, Object?> toMap() => {
    'name': name.trim(),
    'email': email.trim().toLowerCase(),
    'studentId': studentId.trim(),
    'program': program.trim(),
    'role': role,
    'active': active,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

@immutable
class DocumentType {
  const DocumentType({
    required this.id,
    required this.name,
    required this.description,
    required this.processingDays,
    required this.active,
  });

  final String id;
  final String name;
  final String description;
  final int processingDays;
  final bool active;

  factory DocumentType.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return DocumentType(
      id: snapshot.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      processingDays: (data['processingDays'] as num?)?.toInt() ?? 3,
      active: data['active'] as bool? ?? true,
    );
  }
}

@immutable
class DocumentRequest {
  const DocumentRequest({
    required this.id,
    required this.reference,
    required this.ownerId,
    required this.studentName,
    required this.studentEmail,
    required this.documentType,
    required this.purpose,
    required this.copies,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.preferredPickupAt,
  });

  final String id;
  final String reference;
  final String ownerId;
  final String studentName;
  final String studentEmail;
  final String documentType;
  final String purpose;
  final int copies;
  final String notes;
  final String status;
  final DateTime? createdAt;
  final DateTime? preferredPickupAt;

  factory DocumentRequest.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return DocumentRequest(
      id: snapshot.id,
      reference: data['reference'] as String? ?? snapshot.id,
      ownerId: data['ownerId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      studentEmail: data['studentEmail'] as String? ?? '',
      documentType: data['documentType'] as String? ?? '',
      purpose: data['purpose'] as String? ?? '',
      copies: (data['copies'] as num?)?.toInt() ?? 1,
      notes: data['notes'] as String? ?? '',
      status: data['status'] as String? ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      preferredPickupAt: (data['preferredPickupAt'] as Timestamp?)?.toDate(),
    );
  }
}

String formatPickupDate(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} • $hour:$minute $period';
}

@immutable
class StudentNotification {
  const StudentNotification({
    required this.id,
    required this.ownerId,
    required this.requestId,
    required this.reference,
    required this.documentType,
    required this.status,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String requestId;
  final String reference;
  final String documentType;
  final String status;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  factory StudentNotification.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return StudentNotification(
      id: snapshot.id,
      ownerId: data['ownerId'] as String? ?? '',
      requestId: data['requestId'] as String? ?? '',
      reference: data['reference'] as String? ?? '',
      documentType: data['documentType'] as String? ?? '',
      status: data['status'] as String? ?? '',
      type: data['type'] as String? ?? 'status_update',
      title: data['title'] as String? ?? 'Request update',
      message: data['message'] as String? ?? '',
      isRead: data['read'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class DocuTrackService {
  DocuTrackService._();

  static final instance = DocuTrackService._();
  static const requestPageSize = 20;
  static const _standardDocumentTypes =
      <({String id, String name, String description, int processingDays})>[
        (
          id: 'standard_enrollment_form',
          name: 'Enrollment Form',
          description: 'Official form for enrollment-related requests.',
          processingDays: 3,
        ),
        (
          id: 'standard_good_moral',
          name: 'Good Moral Certificate',
          description: 'Certificate of good moral character.',
          processingDays: 5,
        ),
        (
          id: 'standard_tor',
          name: 'Transcript of Records (TOR)',
          description: 'Official record of completed courses and grades.',
          processingDays: 10,
        ),
        (
          id: 'standard_certificate_of_grades',
          name: 'Certificate of Grades',
          description: 'Certified grades for a selected academic term.',
          processingDays: 5,
        ),
        (
          id: 'standard_certificate_of_enrollment',
          name: 'Certificate of Enrollment',
          description: 'Proof of current or past enrollment.',
          processingDays: 3,
        ),
        (
          id: 'standard_certificate_of_graduation',
          name: 'Certificate of Graduation',
          description: 'Certification that the student has graduated.',
          processingDays: 5,
        ),
        (
          id: 'standard_diploma',
          name: 'Diploma',
          description: 'Diploma issuance or replacement request.',
          processingDays: 10,
        ),
      ];

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _random = Random.secure();
  late final Stream<User?> _authStateStream = auth.authStateChanges();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _studentStream =
      firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .snapshots();
  final Map<String, Stream<DocumentSnapshot<Map<String, dynamic>>>>
  _profileStreams = {};
  final Map<String, Stream<QuerySnapshot<Map<String, dynamic>>>>
  _requestStreams = {};
  final Map<String, Stream<DocumentSnapshot<Map<String, dynamic>>>>
  _requestDocumentStreams = {};
  final Map<bool, Stream<QuerySnapshot<Map<String, dynamic>>>>
  _documentTypeStreams = {};
  final Map<String, Stream<QuerySnapshot<Map<String, dynamic>>>>
  _notificationStreams = {};
  final Map<String, Stream<QuerySnapshot<Map<String, dynamic>>>>
  _unreadNotificationStreams = {};

  User? get currentUser => auth.currentUser;

  Stream<User?> authChanges() => _authStateStream;

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile(String uid) =>
      _profileStreams.putIfAbsent(
        uid,
        () => firestore.collection('users').doc(uid).snapshots(),
      );

  Future<void> signIn(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw Exception(_authMessage(error));
    }
  }

  Future<void> registerStudent({
    required String name,
    required String email,
    required String password,
    required String studentId,
    required String program,
  }) async {
    UserCredential? credential;
    try {
      credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('Firebase did not create the account.');
      await firestore.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'studentId': studentId.trim(),
        'program': program.trim(),
        'role': 'student',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await user.reload();
      final refreshed = auth.currentUser;
      if (refreshed == null || refreshed.uid != user.uid) {
        throw Exception('Your sign-in session could not be refreshed.');
      }
    } on FirebaseAuthException catch (error) {
      throw Exception(_authMessage(error));
    } catch (error) {
      var cleanupFailure = '';
      try {
        await credential?.user?.delete();
      } on FirebaseAuthException catch (cleanupError) {
        cleanupFailure =
            ' Firebase could not remove the incomplete authentication account: ${_authMessage(cleanupError)}';
      } catch (cleanupError) {
        cleanupFailure =
            ' Firebase could not remove the incomplete authentication account: $cleanupError';
      }
      if (error is FirebaseException) {
        final reason = _firestoreMessage(error);
        throw Exception(
          'Firebase Authentication created the account, but its student profile could not be saved. $reason$cleanupFailure',
        );
      }
      throw Exception(
        'The student profile could not be saved: $error$cleanupFailure',
      );
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw Exception(_authMessage(error));
    }
  }

  Future<void> updateOwnStudentProfile({
    required String uid,
    required String name,
    required String studentId,
    required String program,
  }) async {
    final user = auth.currentUser;
    if (user == null || user.uid != uid) {
      throw Exception('Sign in to update your profile.');
    }
    try {
      await firestore.collection('users').doc(uid).update({
        'name': name.trim(),
        'studentId': studentId.trim(),
        'program': program.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw Exception(_firestoreMessage(error));
    }
  }

  Future<void> updateOwnAdminName({
    required String uid,
    required String name,
  }) async {
    final user = auth.currentUser;
    final trimmedName = name.trim();
    if (user == null || user.uid != uid) {
      throw Exception('Sign in to update your profile.');
    }
    if (trimmedName.isEmpty) {
      throw Exception('Enter your name.');
    }
    try {
      await firestore.collection('users').doc(uid).update({
        'name': trimmedName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      throw Exception(_firestoreMessage(error));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw Exception(
        'Sign in with an email and password to change your password.',
      );
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      throw Exception(_authMessage(error));
    }
  }

  Future<void> signOut() => auth.signOut();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchStudents() => _studentStream;

  Future<void> createStudent({
    required String name,
    required String email,
    required String password,
    required String studentId,
    required String program,
  }) async {
    final currentAdmin = auth.currentUser;
    if (currentAdmin == null) throw Exception('Sign in as an administrator.');

    final secondary = await Firebase.initializeApp(
      name: 'student-${DateTime.now().microsecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondary);
    User? createdUser;
    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('Firebase did not create the account.');
      createdUser = user;
      await firestore.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'studentId': studentId.trim(),
        'program': program.trim(),
        'role': 'student',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (error) {
      throw Exception(_authMessage(error));
    } catch (error) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } on FirebaseAuthException catch (cleanupError) {
          throw Exception(
            'Student profile creation failed ($error), and the new authentication account could not be rolled back (${cleanupError.message ?? cleanupError.code}).',
          );
        }
      }
      rethrow;
    } finally {
      await secondaryAuth.signOut();
      await secondary.delete();
    }
  }

  Future<void> updateStudent(StudentProfile student) async {
    await firestore.collection('users').doc(student.id).update({
      'name': student.name.trim(),
      'studentId': student.studentId.trim(),
      'program': student.program.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deactivateStudent(String id) async {
    await firestore.collection('users').doc(id).update({
      'active': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setStudentActive(String id, bool active) async {
    await firestore.collection('users').doc(id).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchDocumentTypes({
    bool includeInactive = false,
  }) => _documentTypeStreams.putIfAbsent(includeInactive, () {
    final collection = firestore.collection('documentTypes');
    return includeInactive
        ? collection.snapshots()
        : collection.where('active', isEqualTo: true).snapshots();
  });

  Future<int> addStandardDocumentTypes() async {
    final collection = firestore.collection('documentTypes');
    final snapshot = await collection.get();
    final existingNames = snapshot.docs
        .map(
          (document) =>
              (document.data()['name'] as String? ?? '').trim().toLowerCase(),
        )
        .toSet();
    final missingTypes = _standardDocumentTypes
        .where((type) => !existingNames.contains(type.name.toLowerCase()))
        .toList();
    if (missingTypes.isEmpty) return 0;

    final batch = firestore.batch();
    for (final type in missingTypes) {
      batch.set(collection.doc(type.id), {
        'name': type.name,
        'description': type.description,
        'processingDays': type.processingDays,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return missingTypes.length;
  }

  Future<void> saveDocumentType({
    String? id,
    required String name,
    required String description,
    required int processingDays,
    required bool active,
  }) async {
    final reference = id == null
        ? firestore.collection('documentTypes').doc()
        : firestore.collection('documentTypes').doc(id);
    await reference.set({
      'name': name.trim(),
      'description': description.trim(),
      'processingDays': processingDays,
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
      if (id == null) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteDocumentType(String id) =>
      firestore.collection('documentTypes').doc(id).delete();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRequests({
    required bool admin,
    required String uid,
    int? limit,
  }) => _requestStreams.putIfAbsent('$admin:$uid:$limit', () {
    final collection = firestore.collection('requests');
    Query<Map<String, dynamic>> query = admin
        ? collection
        : collection.where('ownerId', isEqualTo: uid);
    if (limit != null) {
      query = query.orderBy('createdAt', descending: true).limit(limit);
    }
    return query.snapshots();
  });

  Future<QuerySnapshot<Map<String, dynamic>>> getRequestPage({
    required bool admin,
    required String uid,
    required DocumentSnapshot<Map<String, dynamic>> startAfter,
  }) {
    final collection = firestore.collection('requests');
    final query = admin
        ? collection
        : collection.where('ownerId', isEqualTo: uid);
    return query
        .orderBy('createdAt', descending: true)
        .startAfterDocument(startAfter)
        .limit(requestPageSize)
        .get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRequest(String id) =>
      _requestDocumentStreams.putIfAbsent(
        id,
        () => firestore.collection('requests').doc(id).snapshots(),
      );

  Stream<QuerySnapshot<Map<String, dynamic>>> watchNotifications(String uid) =>
      _notificationStreams.putIfAbsent(
        uid,
        () => firestore
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
      );

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUnreadNotifications(
    String uid,
  ) => _unreadNotificationStreams.putIfAbsent(
    uid,
    () => firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .limit(100)
        .snapshots(),
  );

  Future<void> markNotificationRead(String uid, String notificationId) =>
      firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true, 'readAt': FieldValue.serverTimestamp()});

  Future<void> markAllNotificationsRead(String uid) async {
    final notifications = await firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    for (var start = 0; start < notifications.docs.length; start += 450) {
      final batch = firestore.batch();
      final end = min(start + 450, notifications.docs.length);
      for (final notification in notifications.docs.sublist(start, end)) {
        batch.update(notification.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Future<String> createRequest({
    required StudentProfile student,
    required String documentType,
    required String purpose,
    required int copies,
    required String notes,
    DateTime? preferredPickupAt,
  }) async {
    final collection = firestore.collection('requests');
    final reference = collection.doc();
    final date = DateTime.now();
    final suffix = _random
        .nextInt(0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase();
    final requestNumber = 'DOC-${date.year}-$suffix';
    final notification = firestore
        .collection('users')
        .doc(student.id)
        .collection('notifications')
        .doc();
    final batch = firestore.batch();
    batch.set(reference, {
      'reference': requestNumber,
      'ownerId': student.id,
      'studentName': student.name,
      'studentEmail': student.email,
      'documentType': documentType,
      'purpose': purpose,
      'copies': copies,
      'notes': notes.trim(),
      'status': 'Pending',
      if (preferredPickupAt != null)
        'preferredPickupAt': Timestamp.fromDate(preferredPickupAt),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      notification,
      _notificationData(
        ownerId: student.id,
        requestId: reference.id,
        reference: requestNumber,
        documentType: documentType,
        status: 'Pending',
        title: 'Request received',
        message: 'Your request has been received.',
        type: 'request_received',
      ),
    );
    await batch.commit();
    return requestNumber;
  }

  Future<void> updateRequestStatus(
    DocumentRequest request,
    String status,
  ) async {
    if (request.status == status) return;
    final requestReference = firestore.collection('requests').doc(request.id);
    final notification = firestore
        .collection('users')
        .doc(request.ownerId)
        .collection('notifications')
        .doc();
    final (title, baseMessage) = _statusNotification(status);
    final message =
        status == 'Ready for Claim' && request.preferredPickupAt != null
        ? '$baseMessage Review your preferred pickup time in request details.'
        : baseMessage;
    await firestore.runTransaction((transaction) async {
      final current = await transaction.get(requestReference);
      if (!current.exists) {
        throw StateError('This request no longer exists.');
      }
      final currentStatus = current.data()?['status'] as String? ?? 'Pending';
      if (currentStatus == status) return;
      transaction.update(requestReference, {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(
        notification,
        _notificationData(
          ownerId: request.ownerId,
          requestId: request.id,
          reference: request.reference,
          documentType: request.documentType,
          status: status,
          title: title,
          message: message,
          type: 'status_update',
        ),
      );
    });
  }

  Map<String, Object?> _notificationData({
    required String ownerId,
    required String requestId,
    required String reference,
    required String documentType,
    required String status,
    required String title,
    required String message,
    required String type,
  }) => {
    'ownerId': ownerId,
    'requestId': requestId,
    'reference': reference,
    'documentType': documentType,
    'status': status,
    'title': title,
    'message': message,
    'type': type,
    'read': false,
    'createdAt': FieldValue.serverTimestamp(),
  };

  (String, String) _statusNotification(String status) => switch (status) {
    'Verified' => ('Request verified', 'Your request has been verified.'),
    'Processing' => (
      'Processing started',
      'Processing has begun for your request.',
    ),
    'Ready for Claim' => (
      'Document ready',
      'Your document is ready for claim.',
    ),
    'Completed' => (
      'Request completed',
      'Your document has been released and your request is complete.',
    ),
    'Rejected' => ('Request rejected', 'Your request was rejected.'),
    _ => ('Request updated', 'Your request status changed to $status.'),
  };

  Future<void> deleteRequest(String id) =>
      firestore.collection('requests').doc(id).delete();

  static String formatFirestoreError(Object error) {
    if (error is FirebaseException) return _firestoreMessageStatic(error);
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _authMessage(FirebaseAuthException error) => switch (error.code) {
    'email-already-in-use' => 'An account already exists for this email.',
    'invalid-email' => 'Enter a valid email address.',
    'invalid-credential' ||
    'user-not-found' ||
    'wrong-password' => 'Email or password is incorrect.',
    'weak-password' => 'Choose a password with at least 6 characters.',
    'requires-recent-login' => 'Sign in again before changing your password.',
    'provider-already-linked' => 'This account does not use an email password.',
    'user-disabled' => 'This account has been disabled.',
    'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
    'network-request-failed' => 'Network error. Check your connection.',
    'operation-not-allowed' => 'Email/password sign-in is disabled. Enable Email/Password under Firebase Console → Authentication → Sign-in method.',
    'unauthorized-domain' => 'This website domain is not authorized. Add it under Firebase Console → Authentication → Settings → Authorized domains.',
    'app-not-authorized' => 'This app is not authorized for the Firebase project. Check the platform app registration and Firebase options.',
    'invalid-api-key' => 'The Firebase API key is invalid. Check the existing Firebase options for this platform.',
    'web-storage-unsupported' => 'Browser storage is unavailable. Enable cookies and site storage, then reload the app.',
    _ => error.message ?? 'Authentication failed. Please try again.',
  };

  static String _firestoreMessageStatic(FirebaseException error) =>
      switch (error.code) {
        'permission-denied' =>
          'Firestore denied this operation. Confirm the signed-in account has an active users/{UID} profile with the correct role, and that each request belongs to that UID. The rules for this operation must also be published to docutrack-4f32d.',
        'unavailable' || 'deadline-exceeded' =>
          'Firestore is unavailable. Check your network and confirm that a Firestore database has been created.',
        'not-found' =>
          'The Firestore database was not found. Create a Cloud Firestore database in this Firebase project.',
        _ =>
          'Firestore error (${error.code}): ${error.message ?? 'Unknown error.'}',
      };

  String _firestoreMessage(FirebaseException error) =>
      _firestoreMessageStatic(error);
}
