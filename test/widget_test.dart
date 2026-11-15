import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:docutrack2/screens/login_screen.dart';
import 'package:docutrack2/screens/account_support_screens.dart';
import 'package:docutrack2/screens/confirmation_screen.dart';
import 'package:docutrack2/screens/profile_screen.dart';
import 'package:docutrack2/screens/register_screen.dart';
import 'package:docutrack2/screens/request_form_screen.dart';
import 'package:docutrack2/screens/splash_screen.dart';
import 'package:docutrack2/screens/Admin/admin_profile_screen.dart';
import 'package:docutrack2/services/docutrack_service.dart';
import 'package:docutrack2/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('splash opens student sign-in', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const SplashScreen(),
        routes: {'/login': (_) => const LoginScreen()},
      ),
    );

    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back!'), findsOneWidget);
  });

  testWidgets('login validates credentials before contacting Firebase', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('registration form identifies accounts as student accounts', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    expect(find.text('Create Student Account'), findsOneWidget);
    expect(
      find.text('Your account will be registered as a student.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Full Name is required.'), findsOneWidget);
  });

  testWidgets('student request form collects a preferred pickup time', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RequestFormScreen(
          documentType: DocumentType(
            id: 'transcript',
            name: 'Transcript of Records',
            description: 'Official academic record.',
            processingDays: 5,
            active: true,
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Preferred Pickup Date and Time'));
    expect(find.text('Choose date'), findsOneWidget);
    expect(find.text('Choose time'), findsOneWidget);
    expect(find.textContaining('not a confirmed appointment'), findsOneWidget);
  });

  testWidgets('confirmation returns to the existing home route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: Center(child: Text('Home screen'))),
        routes: {
          '/confirmation': (_) =>
              const ConfirmationScreen(reference: 'DOC-2026-ABC123'),
        },
      ),
    );
    Navigator.of(tester.element(find.text('Home screen')))
        .pushNamed('/confirmation');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Back to Home'));
    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();

    expect(find.text('Home screen'), findsOneWidget);
    expect(find.text('Request submitted'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile account and support options open their screens', (
    tester,
  ) async {
    const profile = StudentProfile(
      id: 'student-1',
      name: 'Test Student',
      email: 'student@example.com',
      studentId: '12345',
      program: 'Computer Science',
      role: 'student',
      active: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            profile: profile,
            isDarkMode: true,
            onDarkModeChanged: (_) async {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Personal Information'));
    await tester.pumpAndSettle();
    expect(find.text('Your details'), findsOneWidget);
    expect(find.text('student@example.com'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();
    expect(find.text('Current password'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Help & Support'));
    await tester.pumpAndSettle();
    expect(find.text('How do I request a document?'), findsOneWidget);
    await tester.tap(find.text('How do I request a document?'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('From Home, choose Start a request.'),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('About DocuTrack'));
    await tester.pumpAndSettle();
    expect(find.text('Student Document Portal'), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);
  });

  testWidgets('password change validates matching new passwords', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), 'old-password');
    await tester.enterText(find.byType(TextFormField).at(1), 'new-password');
    await tester.enterText(find.byType(TextFormField).at(2), 'different');
    await tester.ensureVisible(find.text('Update password'));
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('profile appearance switch requests light theme', (tester) async {
    bool? selectedTheme;
    const profile = StudentProfile(
      id: 'student-1',
      name: 'Test Student',
      email: 'student@example.com',
      studentId: '12345',
      program: 'Computer Science',
      role: 'student',
      active: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            profile: profile,
            isDarkMode: true,
            onDarkModeChanged: (enabled) async {
              selectedTheme = enabled;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(selectedTheme, isFalse);
  });

  testWidgets('admin profile shows account details and changes appearance', (
    tester,
  ) async {
    bool? selectedTheme;
    const profile = StudentProfile(
      id: 'admin-1',
      name: 'Test Administrator',
      email: 'admin@example.com',
      studentId: '',
      program: '',
      role: 'admin',
      active: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminProfileScreen(
            profile: profile,
            isDarkMode: true,
            onDarkModeChanged: (enabled) async {
              selectedTheme = enabled;
            },
          ),
        ),
      ),
    );

    expect(find.text('Admin Profile'), findsOneWidget);
    expect(find.text('Test Administrator'), findsNWidgets(2));
    expect(find.text('admin@example.com'), findsNWidgets(2));
    expect(find.text('Administrator'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(selectedTheme, isFalse);
  });

  testWidgets('updates navigation shows unread notification count', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            index: 0,
            unreadCount: 3,
            onTap: _ignoreTab,
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('Updates'), findsOneWidget);
  });

  test('firestore permission errors show actionable guidance', () {
    final message = DocuTrackService.formatFirestoreError(
      FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      ),
    );

    expect(
      message,
      contains('Publish firestore.rules from the project root'),
    );
  });

  testWidgets('animated state changes respect reduced-motion settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: AppAnimatedSwitcher(
              child: Text('Loading', key: ValueKey('loading')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: AppAnimatedSwitcher(
              child: Text('Loaded', key: ValueKey('loaded')),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loaded'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading indicator is static when reduced motion is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: AppLoadingIndicator()),
        ),
      ),
    );

    expect(find.byIcon(Icons.hourglass_empty_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('ambient backdrop animates behind app content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppBackdrop(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: Text('App content')),
          ),
        ),
      ),
    );
    final backdrop = find.byKey(const ValueKey('app-ambient-backdrop'));
    final initialPainter = tester.widget<CustomPaint>(backdrop).painter;

    await tester.pump(const Duration(seconds: 3));

    final updatedPainter = tester.widget<CustomPaint>(backdrop).painter;
    expect(identical(initialPainter, updatedPainter), isFalse);
    expect(find.text('App content'), findsOneWidget);
  });

  testWidgets('tab transitions animate and preserve each page state', (
    tester,
  ) async {
    final firstController = TextEditingController();
    var selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: AnimatedIndexedStack(
                    index: selectedIndex,
                    children: [
                      TextField(
                        key: const ValueKey('first-page'),
                        controller: firstController,
                      ),
                      const Text('Second page', key: ValueKey('second-page')),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(
                    () => selectedIndex = selectedIndex == 0 ? 1 : 0,
                  ),
                  child: const Text('Switch page'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('first-page')), 'saved');
    await tester.tap(find.text('Switch page'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Second page'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch page'));
    await tester.pumpAndSettle();

    expect(firstController.text, 'saved');
    expect(tester.takeException(), isNull);
    firstController.dispose();
  });

  testWidgets('authentication theme control requests the alternate theme', (
    tester,
  ) async {
    AppColors.isDarkMode = true;
    bool? selectedTheme;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppThemeToggle(
            onChanged: (enabled) async {
              selectedTheme = enabled;
              AppColors.isDarkMode = enabled;
            },
          ),
        ),
      ),
    );

    expect(find.byTooltip('Switch to light theme'), findsOneWidget);
    await tester.tap(find.byTooltip('Switch to light theme'));
    await tester.pumpAndSettle();

    expect(selectedTheme, isFalse);
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Switch to dark theme'), findsOneWidget);
    await tester.tap(find.byTooltip('Switch to dark theme'));
    await tester.pumpAndSettle();

    expect(selectedTheme, isTrue);
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Switch to light theme'), findsOneWidget);
  });

  test('shared palette interpolates between light and dark themes', () {
    AppColors.setThemeTransition(false, 0.5);

    expect(
      AppColors.background,
      Color.lerp(const Color(0xFFF4F7FC), const Color(0xFF0A1020), 0.5),
    );
    expect(
      AppColors.primary,
      Color.lerp(const Color(0xFF1D5FD0), const Color(0xFF72A5FF), 0.5),
    );

    AppColors.isDarkMode = true;
  });

  test('brand wordmark maintains readable contrast during theme changes', () {
    for (var step = 0; step <= 100; step++) {
      final darkness = step / 100;
      AppColors.setThemeTransition(darkness >= 0.5, darkness);

      final backgroundLuminance = AppColors.background.computeLuminance();
      expect(
        _contrast(AppColors.brandText.computeLuminance(), backgroundLuminance),
        greaterThanOrEqualTo(4.5),
        reason: 'Docu contrast at darkness=$darkness',
      );
      expect(
        _contrast(
          AppColors.brandAccent.computeLuminance(),
          backgroundLuminance,
        ),
        greaterThanOrEqualTo(3),
        reason: 'Track contrast at darkness=$darkness',
      );
    }

    AppColors.isDarkMode = true;
  });

  testWidgets('brand wordmark updates as theme background animates', (
    tester,
  ) async {
    AppColors.isDarkMode = true;
    await tester.pumpWidget(const MaterialApp(home: BrandLogo()));

    RichText wordmark() => tester.widget<RichText>(find.byType(RichText));

    List<InlineSpan> spans() => (wordmark().text as TextSpan).children!;

    expect((spans().first as TextSpan).style!.color, Colors.white);

    AppColors.setThemeTransition(false, 0);
    await tester.pump();

    expect((spans().first as TextSpan).style!.color, Colors.black);
    AppColors.isDarkMode = true;
  });
}

double _contrast(double firstLuminance, double secondLuminance) {
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

void _ignoreTab(int _) {}
