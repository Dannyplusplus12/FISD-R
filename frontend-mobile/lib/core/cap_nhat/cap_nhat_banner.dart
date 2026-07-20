import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cap_nhat_ota_provider.dart';
import 'cap_nhat_pwa_provider.dart';

/// Bọc quanh toàn bộ app (qua `MaterialApp.builder`) để hiện banner khi có
/// bản cập nhật mới:
/// - Android: bản vá Shorebird đã tải xong, chờ đóng/mở lại app.
/// - Web: service worker mới đã cài xong, chờ tải lại trang.
class CapNhatBanner extends ConsumerStatefulWidget {
  final Widget child;
  const CapNhatBanner({required this.child, super.key});

  @override
  ConsumerState<CapNhatBanner> createState() => _CapNhatBannerState();
}

class _CapNhatBannerState extends ConsumerState<CapNhatBanner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(capNhatOtaProvider.notifier).kiemTraLai();
    }
  }

  @override
  Widget build(BuildContext context) {
    final otaSanSang =
        ref.watch(capNhatOtaProvider).valueOrNull ==
        TrangThaiCapNhatOta.sanSangKhoiDongLai;
    final pwaSanSang = ref.watch(capNhatPwaProvider);

    final hienBanner = otaSanSang || pwaSanSang;
    final noiDung = pwaSanSang
        ? 'Đã có phiên bản mới. Tải lại trang để cập nhật.'
        : 'Đã có bản cập nhật mới. Đóng và mở lại ứng dụng để áp dụng.';
    final nhanNut = pwaSanSang ? 'Tải lại' : 'Đóng app';
    final xuLyNhan = pwaSanSang
        ? () => ref.read(capNhatPwaProvider.notifier).taiLaiTrang()
        : () => SystemNavigator.pop();

    return Stack(
      children: [
        widget.child,
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          top: hienBanner ? 0 : -120,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Material(
              color: const Color(0xFF1A1A2E),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.system_update_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        noiDung,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: xuLyNhan,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.amberAccent,
                      ),
                      child: Text(
                        nhanNut,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
