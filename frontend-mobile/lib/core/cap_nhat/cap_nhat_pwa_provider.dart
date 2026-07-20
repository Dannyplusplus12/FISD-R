import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lang_nghe_pwa.dart';

/// true khi trình duyệt đã tải xong một bản PWA mới hơn, chờ tải lại trang
/// để áp dụng. Chỉ có ý nghĩa trên nền tảng web.
final capNhatPwaProvider =
    NotifierProvider<CapNhatPwaNotifier, bool>(CapNhatPwaNotifier.new);

class CapNhatPwaNotifier extends Notifier<bool> {
  bool _daDangKy = false;

  @override
  bool build() {
    if (!_daDangKy) {
      _daDangKy = true;
      dangKyLangNgheCapNhatWeb(() => state = true);
    }
    return false;
  }

  void taiLaiTrang() => taiLaiTrangWeb();
}
