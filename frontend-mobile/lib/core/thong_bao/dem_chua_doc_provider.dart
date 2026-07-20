import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../realtime/realtime_socket.dart';

const _kTienTo = 'chua_doc_';

/// Đếm tin nhắn chưa đọc theo từng kênh chat — chỉ tăng khi kênh không đang mở.
/// Nguồn dữ liệu hiện tại là sự kiện realtime `chat_message_new` (khi app đang
/// chạy); khi có push notification (Phần B) sẽ ghi thêm vào đúng key
/// SharedPreferences này từ background handler.
class DemChuaDocNotifier extends Notifier<Map<int, int>> {
  int? _kenhDangMo;
  bool _daInit = false;
  StreamSubscription? _sub;

  @override
  Map<int, int> build() {
    ref.onDispose(() => _sub?.cancel());
    _taiTuLocal();
    return {};
  }

  Future<void> _taiTuLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <int, int>{};
    for (final k in prefs.getKeys()) {
      if (!k.startsWith(_kTienTo)) continue;
      final id = int.tryParse(k.substring(_kTienTo.length));
      final v = prefs.getInt(k);
      if (id != null && v != null && v > 0) map[id] = v;
    }
    if (map.isNotEmpty) state = map;
  }

  void init(int nhanVienId) {
    if (_daInit) return;
    _daInit = true;
    final socket = ref.read(realtimeSocketProvider);
    socket.ketNoi(nhanVienId);
    _sub = socket.messages.listen((msg) {
      if (msg['type'] != 'chat_message_new') return;
      final data = msg['data'] as Map<String, dynamic>?;
      if (data == null) return;
      final kenhId = data['ma_kenh'] as int?;
      final nguoiGuiId = data['nguoi_gui_id'] as int?;
      if (kenhId == null || nguoiGuiId == nhanVienId || kenhId == _kenhDangMo) return;
      _tang(kenhId);
    });
  }

  Future<void> _tang(int kenhId) async {
    final moi = (state[kenhId] ?? 0) + 1;
    state = {...state, kenhId: moi};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_kTienTo$kenhId', moi);
  }

  /// Gọi khi mở/đóng 1 kênh — trong lúc đang mở, tin nhắn mới của kênh đó
  /// không tính là "chưa đọc".
  void datKenhDangMo(int? kenhId) => _kenhDangMo = kenhId;

  Future<void> xoa(int kenhId) async {
    if (!state.containsKey(kenhId)) return;
    final moi = {...state}..remove(kenhId);
    state = moi;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kTienTo$kenhId');
  }

  int get tong => state.values.fold(0, (a, b) => a + b);
}

final demChuaDocProvider = NotifierProvider<DemChuaDocNotifier, Map<int, int>>(DemChuaDocNotifier.new);
