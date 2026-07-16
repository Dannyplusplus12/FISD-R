import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fisd_shared/fisd_shared.dart';

import '../api/api_client.dart';

/// Kết nối WebSocket realtime dùng chung cho chat, đồng bộ soạn kho, và tín hiệu WebRTC.
/// Tự kết nối lại nếu rớt mạng.
class RealtimeSocket {
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  int? _nhanVienId;
  bool _dangDong = false;

  Stream<Map<String, dynamic>> get messages => _controller.stream;

  void ketNoi(int nhanVienId) {
    if (_channel != null && _nhanVienId == nhanVienId) return;
    _dangDong = false;
    _nhanVienId = nhanVienId;
    _moKetNoi(nhanVienId);
  }

  void _moKetNoi(int nhanVienId) {
    final url = ApiEndpoints.wsRealtime(kBackendUrl, nhanVienId);
    final channel = WebSocketChannel.connect(Uri.parse(url));
    _channel = channel;
    channel.stream.listen(
      (raw) {
        try {
          final msg = jsonDecode(raw as String) as Map<String, dynamic>;
          _controller.add(msg);
        } catch (_) {}
      },
      onDone: () => _thuKetNoiLai(nhanVienId),
      onError: (_) => _thuKetNoiLai(nhanVienId),
      cancelOnError: true,
    );
  }

  void _thuKetNoiLai(int nhanVienId) {
    if (_dangDong || _nhanVienId != nhanVienId) return;
    _channel = null;
    Future.delayed(const Duration(seconds: 3), () {
      if (!_dangDong && _nhanVienId == nhanVienId) _moKetNoi(nhanVienId);
    });
  }

  void gui(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void dong() {
    _dangDong = true;
    _channel?.sink.close();
    _channel = null;
  }
}

final realtimeSocketProvider = Provider<RealtimeSocket>((ref) {
  final socket = RealtimeSocket();
  ref.onDispose(socket.dong);
  return socket;
});
