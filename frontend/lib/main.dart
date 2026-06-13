import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/session/session.dart';
import 'widgets/app_shell.dart' show AppShell, AuthGate;

// ── Entry Point ───────────────────────────────────────────────────────────────
//
// App startup:
//   1. ProviderScope    — wraps the whole app so Riverpod providers work
//   2. SessionNotifier.init() — restores the saved login session from disk
//   3. RootWidget       — shows LoginPage or AppShell depending on session state
//
// Riverpod's ProviderScope must be the outermost widget.  Think of it as a
// "storage box" that all providers live inside.

void main() {
  runApp(
    // ProviderScope is required for Riverpod — it initialises all providers.
    const ProviderScope(
      child: FisdApp(),
    ),
  );
}

class FisdApp extends ConsumerStatefulWidget {
  const FisdApp({super.key});

  @override
  ConsumerState<FisdApp> createState() => _FisdAppState();
}

class _FisdAppState extends ConsumerState<FisdApp> {
  bool _sessionLoaded = false;

  @override
  void initState() {
    super.initState();
    // Restore saved session (employee login) on first launch.
    ref.read(sessionProvider.notifier).init().then((_) {
      setState(() => _sessionLoaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a splash/loading screen while reading SharedPreferences.
    if (!_sessionLoaded) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFFC2C2C2),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'FISD',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),

      // Vietnamese locale so dates and numbers format correctly (e.g. intl package).
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('vi', 'VN'),

      // RootWidget handles the auth gate:
      //   not logged in → LoginPage
      //   logged in      → AppShell (sidebar + content)
      home: const AuthGate(),
    );
  }
}
