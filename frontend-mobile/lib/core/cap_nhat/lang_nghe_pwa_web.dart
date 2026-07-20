import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Lắng nghe service worker mới được cài (bản PWA mới hơn bản đang chạy) và
/// gọi [khiCoBanMoi] khi có. Chỉ báo khi đã có một service worker đang điều
/// khiển trang (tức không phải lần cài đặt đầu tiên).
void dangKyLangNgheCapNhatWeb(void Function() khiCoBanMoi) {
  final container = web.window.navigator.serviceWorker;

  container.ready.toDart.then((registration) {
    registration.onupdatefound = () {
      final dangCai = registration.installing;
      if (dangCai == null) return;

      dangCai.onstatechange = () {
        if (dangCai.state == 'installed' && container.controller != null) {
          khiCoBanMoi();
        }
      }.toJS;
    }.toJS;
  });
}

void taiLaiTrangWeb() => web.window.location.reload();
