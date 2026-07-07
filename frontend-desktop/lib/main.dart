import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'widgets/khung_app.dart';

void main() {
  runApp(const ProviderScope(child: FisdApp()));
}

class FisdApp extends StatelessWidget {
  const FisdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FISD',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
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
      home: const KhungApp(),
    );
  }
}
