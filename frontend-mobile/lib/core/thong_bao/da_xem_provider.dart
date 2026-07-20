import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kTienTo = 'da_xem_';

class DaXemNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    _taiTuLocal();
    return {};
  }

  Future<void> _taiTuLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_kTienTo) && prefs.getBool(k) == true);
    state = keys.map((k) => k.substring(_kTienTo.length)).toSet();
  }

  bool daXem(String key) => state.contains(key);

  Future<void> danhDauDaXem(String key) async {
    if (state.contains(key)) return;
    state = {...state, key};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kTienTo$key', true);
  }
}

final daXemProvider = NotifierProvider<DaXemNotifier, Set<String>>(DaXemNotifier.new);
