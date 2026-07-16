import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Desktop không có luồng đăng nhập PIN như mobile — chat cần biết "đây là ai"
/// nên lưu 1 lựa chọn nhân viên cục bộ trên máy (không phải phiên đăng nhập thật).
class DanhTinhChat {
  final int id;
  final String ten;
  const DanhTinhChat({required this.id, required this.ten});
}

class DanhTinhChatNotifier extends StateNotifier<AsyncValue<DanhTinhChat?>> {
  static const _kId = 'chat_nv_id';
  static const _kTen = 'chat_nv_ten';

  DanhTinhChatNotifier() : super(const AsyncValue.loading()) {
    _tai();
  }

  Future<void> _tai() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_kId);
    final ten = prefs.getString(_kTen) ?? '';
    state = AsyncValue.data(id != null ? DanhTinhChat(id: id, ten: ten) : null);
  }

  Future<void> chon(int id, String ten) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kId, id);
    await prefs.setString(_kTen, ten);
    state = AsyncValue.data(DanhTinhChat(id: id, ten: ten));
  }

  Future<void> doiNguoiDung() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kId);
    await prefs.remove(_kTen);
    state = const AsyncValue.data(null);
  }
}

final danhTinhChatProvider =
    StateNotifierProvider<DanhTinhChatNotifier, AsyncValue<DanhTinhChat?>>((ref) => DanhTinhChatNotifier());
