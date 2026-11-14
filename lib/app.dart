import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/Admin/admin_shell.dart';
import 'screens/app_shell.dart';
import 'screens/document_types_screen.dart';
import 'screens/confirmation_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/request_form_screen.dart';
import 'screens/request_details_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/track_request_screen.dart';
import 'services/docutrack_service.dart';
import 'ui.dart';

class DocuTrackApp extends StatefulWidget {
  const DocuTrackApp({super.key});

  @override
  State<DocuTrackApp> createState() => _DocuTrackAppState();
}

class _DocuTrackAppState extends State<DocuTrackApp>
    with SingleTickerProviderStateMixin {
  late Future<FirebaseApp> _firebase;
  late final AnimationController _themeTransition;
  double _themeTransitionStart = 1;
  double _themeTransitionEnd = 1;
  bool _themeTransitionTarget = true;
  static const _appearancePreferenceKey = 'appearance_dark_mode';

  @override
  void initState() {
    super.initState();
    _themeTransition = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..addListener(_updateThemeTransition);
    _themeTransitionTarget = AppColors.isDarkMode;
    _firebase = _initializeFirebase();
    _loadAppearancePreference();
  }

  void _updateThemeTransition() {
    final darkness =
        _themeTransitionStart +
        (_themeTransitionEnd - _themeTransitionStart) * _themeTransition.value;
    AppColors.setThemeTransition(_themeTransitionTarget, darkness);
    if (mounted) setState(() {});
  }

  Future<void> _loadAppearancePreference() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final isDarkMode = preferences.getBool(_appearancePreferenceKey) ?? true;
      if (!mounted) return;
      setState(() => AppColors.isDarkMode = isDarkMode);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'DocuTrack appearance settings',
          context: ErrorDescription('while loading the saved theme preference'),
        ),
      );
    }
  }

  Future<void> _setDarkMode(bool enabled) async {
    _themeTransitionStart = AppColors.darkness;
    _themeTransitionEnd = enabled ? 1 : 0;
    _themeTransitionTarget = enabled;
    AppColors.setThemeTransition(enabled, _themeTransitionStart);
    _themeTransition.forward(from: 0);
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_appearancePreferenceKey, enabled);
    if (!saved) {
      throw Exception('Your appearance preference could not be saved.');
    }
  }

  void _retryFirebase() {
    setState(() {
      _firebase = _initializeFirebase();
    });
  }

  Future<FirebaseApp> _initializeFirebase() {
    if (Firebase.apps.isNotEmpty) return Future.value(Firebase.app());
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  void dispose() {
    _themeTransition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DocuTrack',
    debugShowCheckedModeBanner: false,
    themeMode: AppColors.isDarkMode ? ThemeMode.dark : ThemeMode.light,
    themeAnimationDuration: const Duration(milliseconds: 760),
    themeAnimationCurve: Curves.easeInOutCubicEmphasized,
    builder: (context, child) =>
        AppBackdrop(child: child ?? const SizedBox.shrink()),
    theme: _buildTheme(Brightness.light),
    darkTheme: _buildTheme(Brightness.dark),
    routes: {
      '/login': (_) => LoginScreen(onDarkModeChanged: _setDarkMode),
      '/register': (_) => RegisterScreen(onDarkModeChanged: _setDarkMode),
      '/forgot-password': (_) =>
          ForgotPasswordScreen(onDarkModeChanged: _setDarkMode),
      '/documents': (_) => const DocumentTypesScreen(),
      '/request-form': (context) => RequestFormScreen(
        documentType:
            ModalRoute.of(context)!.settings.arguments as DocumentType,
      ),
      '/confirmation': (context) => ConfirmationScreen(
        reference: ModalRoute.of(context)!.settings.arguments as String,
      ),
      '/request-details': (context) => RequestDetailsScreen(
        request: ModalRoute.of(context)!.settings.arguments as DocumentRequest,
      ),
      '/track': (context) => TrackRequestScreen(
        request: ModalRoute.of(context)!.settings.arguments as DocumentRequest,
      ),
    },
    home: FutureBuilder<FirebaseApp>(
      future: _firebase,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _FirebaseSetupError(
            message: snapshot.error.toString(),
            onRetry: _retryFirebase,
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupScreen();
        }
        return AuthGate(
          isDarkMode: AppColors.isDarkMode,
          onDarkModeChanged: _setDarkMode,
        );
      },
    ),
  );

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? const Color(0xFF72A5FF) : const Color(0xFF1D5FD0);
    final background = isDark
        ? const Color(0xFF0A1020)
        : const Color(0xFFF4F7FC);
    final surface = isDark ? const Color(0xFF111A2C) : Colors.white;
    final raisedSurface = isDark
        ? const Color(0xFF17233A)
        : const Color(0xFFEAF0F8);
    final text = isDark ? const Color(0xFFEAF1FF) : const Color(0xFF14233E);
    final muted = isDark ? const Color(0xFF9AAAC4) : const Color(0xFF71809A);
    final border = isDark ? const Color(0xFF293750) : const Color(0xFFE2E9F4);
    final paleBlue = isDark ? const Color(0xFF1A2B49) : const Color(0xFFEAF2FF);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        onPrimary: isDark ? background : Colors.white,
        surface: background,
        onSurface: text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -.4,
        ),
      ),
      textTheme: (isDark ? ThemeData.dark() : ThemeData.light()).textTheme
          .apply(bodyColor: text, displayColor: text),
      iconTheme: IconThemeData(color: muted),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: text,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: isDark ? background : Colors.white,
          backgroundColor: primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: TextStyle(color: muted, height: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: TextStyle(color: text, fontSize: 13),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: text,
        horizontalTitleGap: 12,
        minVerticalPadding: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: primary,
        collapsedIconColor: muted,
        textColor: text,
        collapsedTextColor: text,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: raisedSurface,
        selectedColor: paleBlue,
        disabledColor: raisedSurface.withValues(alpha: .5),
        labelStyle: TextStyle(color: muted, fontSize: 11),
        secondaryLabelStyle: TextStyle(color: primary, fontSize: 11),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        side: BorderSide(color: border),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: paleBlue,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF263550)
            : const Color(0xFF14233E),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SubtlePageTransitionsBuilder(),
          TargetPlatform.iOS: _SubtlePageTransitionsBuilder(),
          TargetPlatform.linux: _SubtlePageTransitionsBuilder(),
          TargetPlatform.macOS: _SubtlePageTransitionsBuilder(),
          TargetPlatform.windows: _SubtlePageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: raisedSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        hintStyle: TextStyle(color: muted.withValues(alpha: .85), fontSize: 13),
        labelStyle: TextStyle(color: muted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border.withValues(alpha: .8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
        prefixIconColor: muted,
        suffixIconColor: muted,
      ),
    );
  }
}

class _SubtlePageTransitionsBuilder extends PageTransitionsBuilder {
  const _SubtlePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.08, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final bool isDarkMode;
  final Future<void> Function(bool enabled) onDarkModeChanged;

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: DocuTrackService.instance.authChanges(),
    builder: (context, authSnapshot) {
      if (authSnapshot.hasError) {
        return _MessageScreen(
          title: 'Could not check your session',
          message: authSnapshot.error.toString(),
          action: TextButton(
            onPressed: DocuTrackService.instance.signOut,
            child: const Text('Return to sign in'),
          ),
        );
      }
      if (authSnapshot.connectionState == ConnectionState.waiting) {
        return const _StartupScreen();
      }
      final user = authSnapshot.data;
      if (user == null) {
        return SplashScreen(onDarkModeChanged: onDarkModeChanged);
      }

      return StreamBuilder(
        stream: DocuTrackService.instance.watchProfile(user.uid),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.hasError) {
            return _MessageScreen(
              title: 'Profile unavailable',
              message:
                  'We could not load your profile. Check your Firestore rules and connection, then try again.\n\n${profileSnapshot.error}',
              action: TextButton(
                onPressed: DocuTrackService.instance.signOut,
                child: const Text('Sign out'),
              ),
            );
          }
          if (!profileSnapshot.hasData) return const _StartupScreen();
          final snapshot = profileSnapshot.data!;
          if (!snapshot.exists) {
            return _MessageScreen(
              title: 'Student profile not found',
              message: 'This Firebase account has no DocuTrack profile. Register again or contact an administrator.',
              action: TextButton(
                onPressed: DocuTrackService.instance.signOut,
                child: const Text('Sign out'),
              ),
            );
          }
          final profile = StudentProfile.fromSnapshot(snapshot);
          if (!profile.active) {
            return _MessageScreen(
              title: 'Account inactive',
              message: 'Contact your school office to restore access.',
              action: TextButton(
                onPressed: DocuTrackService.instance.signOut,
                child: const Text('Sign out'),
              ),
            );
          }
          if (profile.role == 'admin') {
            return AdminShell(
              profile: profile,
              isDarkMode: isDarkMode,
              onDarkModeChanged: onDarkModeChanged,
            );
          }
          if (profile.role == 'student') {
            return AppShell(
              profile: profile,
              isDarkMode: isDarkMode,
              onDarkModeChanged: onDarkModeChanged,
            );
          }
          return _MessageScreen(
            title: 'Account role is not configured',
            message:
                'An administrator must assign this account a DocuTrack role.',
            action: TextButton(
              onPressed: DocuTrackService.instance.signOut,
              child: const Text('Sign out'),
            ),
          );
        },
      );
    },
  );
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandLogo(size: 78),
          SizedBox(height: 22),
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}

class _FirebaseSetupError extends StatelessWidget {
  const _FirebaseSetupError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _MessageScreen(
    title: 'Firebase could not start',
    message:
        'Check the Firebase settings for this app and make sure this platform is registered in your project.\n\n$message',
    action: FilledButton(onPressed: onRetry, child: const Text('Retry')),
  );
}

class _MessageScreen extends StatelessWidget {
  const _MessageScreen({
    required this.title,
    required this.message,
    required this.action,
  });

  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 48, color: AppColors.primary),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 14),
                action,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
