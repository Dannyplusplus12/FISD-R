import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fisd_shared/fisd_shared.dart';

import '../../core/realtime/realtime_socket.dart';
import 'chat_repository.dart';

const _kSuKienDanhSachKenhThayDoi = {
  'channel_create',
  'channel_member_add',
  'channel_member_remove',
  'order_picker_added',
};

final danhSachKenhProvider =
    FutureProvider.autoDispose.family<List<KenhChat>, int>((ref, nhanVienId) {
  final socket = ref.watch(realtimeSocketProvider);
  socket.ketNoi(nhanVienId);
  final sub = socket.messages.listen((msg) {
    if (_kSuKienDanhSachKenhThayDoi.contains(msg['type'])) {
      ref.invalidateSelf();
    }
  });
  ref.onDispose(sub.cancel);
  return ref.watch(chatRepositoryProvider).layDanhSachKenh(nhanVienId);
});

final danhSachNhanVienProvider = FutureProvider.autoDispose<List<NhanVien>>((ref) {
  return ref.watch(chatRepositoryProvider).layDanhSachNhanVien();
});

class TinNhanNotifier extends StateNotifier<AsyncValue<List<TinNhan>>> {
  final ChatRepository repo;
  final RealtimeSocket socket;
  final int kenhId;
  StreamSubscription? _sub;

  TinNhanNotifier(this.repo, this.socket, this.kenhId) : super(const AsyncValue.loading()) {
    _taiLichSu();
    _sub = socket.messages.listen((msg) {
      if (msg['type'] == 'chat_message_new') {
        final data = msg['data'] as Map<String, dynamic>?;
        if (data != null && data['ma_kenh'] == kenhId) {
          final tn = TinNhan.fromJson(data);
          state = state.whenData((list) {
            if (list.any((t) => t.id == tn.id)) return list;
            return [...list, tn];
          });
        }
      }
    });
  }

  Future<void> _taiLichSu() async {
    state = const AsyncValue.loading();
    try {
      final list = await repo.layTinNhan(kenhId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> taiThem() async {
    final hienTai = state.value;
    if (hienTai == null || hienTai.isEmpty) return;
    final them = await repo.layTinNhan(kenhId, beforeId: hienTai.first.id);
    if (them.isEmpty) return;
    state = AsyncValue.data([...them, ...hienTai]);
  }

  Future<void> gui({required int nguoiGuiId, String noiDung = '', List<MultipartFile> files = const []}) async {
    await repo.guiTinNhan(kenhId, nguoiGuiId: nguoiGuiId, noiDung: noiDung, files: files);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final tinNhanKenhProvider = StateNotifierProvider.autoDispose
    .family<TinNhanNotifier, AsyncValue<List<TinNhan>>, int>((ref, kenhId) {
  final repo = ref.watch(chatRepositoryProvider);
  final socket = ref.watch(realtimeSocketProvider);
  return TinNhanNotifier(repo, socket, kenhId);
});
