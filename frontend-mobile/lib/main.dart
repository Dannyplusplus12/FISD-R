import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/trang_chu/trang_chu_page.dart';
import 'features/xac_thuc/dang_nhap_page.dart';
import 'features/xac_thuc/xac_thuc_provider.dart';

void main() {
  runApp(const ProviderScope(child: FisdMobileApp()));
}

class FisdMobileApp extends StatelessWidget {
  const FisdMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FISD',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A1A2E)),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const CongXacThuc(),
    );
  }
}

class CongXacThuc extends ConsumerWidget {
  const CongXacThuc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phien = ref.watch(xacThucProvider).valueOrNull;
    return phien != null ? const TrangChuPage() : const DangNhapPage();
  }
}
