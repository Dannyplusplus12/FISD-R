import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:fisd_shared/fisd_shared.dart';

import '../../core/api/api_client.dart';
import '../../core/realtime/realtime_socket.dart';
import 'danh_tinh_chat_provider.dart';

/// Gọi thoại/video + share màn hình qua WebRTC mesh (mỗi người tham gia kết nối
/// trực tiếp với tất cả người còn lại). Ghi chú: mesh thuần chỉ phù hợp nhóm nhỏ
/// (~4 người) — nhóm đông hơn cần SFU, không nằm trong phạm vi bản này.
class GoiVideoPage extends ConsumerStatefulWidget {
  final int kenhId;
  final String callId;
  final List<ThanhVienChat> nguoiThamGia; // không gồm bản thân
  final DanhTinhChat danhTinh;
  final bool coCamera;

  const GoiVideoPage({
    super.key,
    required this.kenhId,
    required this.callId,
    required this.nguoiThamGia,
    required this.danhTinh,
    this.coCamera = true,
  });

  @override
  ConsumerState<GoiVideoPage> createState() => _GoiVideoPageState();
}

class _GoiVideoPageState extends ConsumerState<GoiVideoPage> {
  final _localRenderer = RTCVideoRenderer();
  final Map<int, RTCPeerConnection> _peers = {};
  final Map<int, RTCVideoRenderer> _remoteRenderers = {};
  MediaStream? _localStream;
  MediaStream? _screenStream;
  List<Map<String, dynamic>> _iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
  ];
  StreamSubscription? _sub;
  late RealtimeSocket _socket;
  bool _micOn = true;
  bool _camOn = true;
  bool _screenSharing = false;
  bool _dangKetNoi = true;

  @override
  void initState() {
    super.initState();
    _khoiTao();
  }

  Future<void> _khoiTao() async {
    await _localRenderer.initialize();
    await _layIceServers();
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': widget.coCamera ? {'facingMode': 'user'} : false,
    });
    _localRenderer.srcObject = _localStream;
    _camOn = widget.coCamera;
    _socket = ref.read(realtimeSocketProvider);
    _dangKyLangNgheTinHieu();
    _baoHieuThamGia();
    if (mounted) setState(() => _dangKetNoi = false);
  }

  /// Báo cho các thành viên khác trong kênh biết mình vừa vào cuộc gọi. Người đã
  /// có mặt từ trước (đang lắng nghe) sẽ chủ động tạo kết nối lại — nhờ vậy vào
  /// giữa chừng một cuộc gọi nhóm đang diễn ra vẫn kết nối được với người cũ,
  /// thay vì chỉ dựa vào danh sách người tham gia cố định lúc mở trang.
  void _baoHieuThamGia({int? chiMotNguoi}) {
    final targets = chiMotNguoi != null
        ? [chiMotNguoi]
        : widget.nguoiThamGia.map((n) => n.id).toList();
    if (targets.isEmpty) return;
    _socket.gui({
      'type': 'rtc_call_join',
      'data': {'target_ids': targets, 'call_id': widget.callId},
    });
  }

  String _tenNguoiThamGia(int id) {
    for (final n in widget.nguoiThamGia) {
      if (n.id == id) return n.ten;
    }
    return 'Người dùng #$id';
  }

  Future<void> _layIceServers() async {
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.get(ApiEndpoints.turnCredentials,
          queryParameters: {'nhan_vien_id': widget.danhTinh.id});
      final data = res.data as Map<String, dynamic>;
      final urls = (data['urls'] as List).cast<String>();
      for (final u in urls) {
        if (u.startsWith('turn:')) {
          _iceServers.add({'urls': u, 'username': data['username'], 'credential': data['credential']});
        }
      }
    } catch (_) {
      // Chưa cấu hình TURN — chỉ dùng STUN công cộng.
    }
  }

  Future<void> _taoKetNoi(int doiPhuongId) async {
    final pc = await createPeerConnection({'iceServers': _iceServers});
    _peers[doiPhuongId] = pc;
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    _remoteRenderers[doiPhuongId] = renderer;

    for (final track in _localStream!.getTracks()) {
      await pc.addTrack(track, _localStream!);
    }

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        renderer.srcObject = event.streams[0];
        if (mounted) setState(() {});
      }
    };

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      _socket.gui({
        'type': 'rtc_ice_candidate',
        'data': {
          'target_id': doiPhuongId,
          'call_id': widget.callId,
          'candidate': candidate.candidate,
          'sdp_mid': candidate.sdpMid,
          'sdp_mline_index': candidate.sdpMLineIndex,
        },
      });
    };

    pc.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        // Kết nối chết (mất mạng tạm thời...) — dọn dẹp rồi báo lại để thử kết nối lại.
        _dongKetNoiVoi(doiPhuongId);
        _baoHieuThamGia(chiMotNguoi: doiPhuongId);
      }
    };

    if (widget.danhTinh.id < doiPhuongId) {
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      _socket.gui({
        'type': 'rtc_offer',
        'data': {
          'target_id': doiPhuongId, 'call_id': widget.callId,
          'sdp': offer.sdp, 'sdp_type': offer.type,
        },
      });
    }
  }

  void _dangKyLangNgheTinHieu() {
    _sub = _socket.messages.listen((msg) async {
      final data = msg['data'] as Map<String, dynamic>?;
      if (data == null || data['call_id'] != widget.callId) return;
      final fromId = data['from_id'] as int?;
      if (fromId == null) return;

      switch (msg['type']) {
        case 'rtc_call_join':
          if (_peers[fromId] == null) {
            if (widget.danhTinh.id < fromId) {
              // Mình có id nhỏ hơn -> chủ động tạo kết nối + gửi offer.
              await _taoKetNoi(fromId);
            } else {
              // Id lớn hơn -> không chủ động offer, chỉ báo lại cho họ biết mình
              // đã có mặt (phòng khi lời chào ban đầu của họ đến trước khi mình
              // vào trang này và bị bỏ lỡ).
              _baoHieuThamGia(chiMotNguoi: fromId);
            }
          }
          break;
        case 'rtc_offer':
          var pc = _peers[fromId];
          if (pc == null) {
            await _taoKetNoi(fromId);
            pc = _peers[fromId];
          }
          await pc!.setRemoteDescription(RTCSessionDescription(data['sdp'] as String, data['sdp_type'] as String));
          final answer = await pc.createAnswer();
          await pc.setLocalDescription(answer);
          _socket.gui({
            'type': 'rtc_answer',
            'data': {'target_id': fromId, 'call_id': widget.callId, 'sdp': answer.sdp, 'sdp_type': answer.type},
          });
          break;
        case 'rtc_answer':
          final pc = _peers[fromId];
          if (pc != null) {
            await pc.setRemoteDescription(RTCSessionDescription(data['sdp'] as String, data['sdp_type'] as String));
          }
          break;
        case 'rtc_ice_candidate':
          final pc = _peers[fromId];
          if (pc != null && data['candidate'] != null) {
            await pc.addCandidate(RTCIceCandidate(
              data['candidate'] as String,
              data['sdp_mid'] as String?,
              (data['sdp_mline_index'] as num?)?.toInt(),
            ));
          }
          break;
        case 'rtc_call_leave':
          await _dongKetNoiVoi(fromId);
          break;
      }
    });
  }

  Future<void> _dongKetNoiVoi(int doiPhuongId) async {
    await _peers[doiPhuongId]?.close();
    _peers.remove(doiPhuongId);
    await _remoteRenderers[doiPhuongId]?.dispose();
    _remoteRenderers.remove(doiPhuongId);
    if (mounted) setState(() {});
  }

  void _toggleMic() {
    final tracks = _localStream?.getAudioTracks() ?? [];
    if (tracks.isEmpty) return;
    tracks.first.enabled = !tracks.first.enabled;
    setState(() => _micOn = tracks.first.enabled);
  }

  void _toggleCam() {
    final tracks = _localStream?.getVideoTracks() ?? [];
    if (tracks.isEmpty) return;
    tracks.first.enabled = !tracks.first.enabled;
    setState(() => _camOn = tracks.first.enabled);
  }

  RTCRtpSender? _timVideoSender(List<RTCRtpSender> senders) {
    for (final s in senders) {
      if (s.track?.kind == 'video') return s;
    }
    return null;
  }

  Future<void> _toggleScreenShare() async {
    if (!_screenSharing) {
      try {
        final display = await navigator.mediaDevices.getDisplayMedia({'video': true, 'audio': false});
        _screenStream = display;
        final screenTrack = display.getVideoTracks().first;
        for (final pc in _peers.values) {
          final sender = _timVideoSender(await pc.getSenders());
          await sender?.replaceTrack(screenTrack);
        }
        _localRenderer.srcObject = display;
        screenTrack.onEnded = () => _toggleScreenShare();
        final targetIds = widget.nguoiThamGia.map((n) => n.id).toList();
        _socket.gui({'type': 'rtc_screen_share_start', 'data': {'target_ids': targetIds, 'call_id': widget.callId}});
        setState(() => _screenSharing = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không chia sẻ được màn hình: $e')));
        }
      }
    } else {
      for (final track in _screenStream?.getTracks() ?? <MediaStreamTrack>[]) {
        await track.stop();
      }
      await _screenStream?.dispose();
      _screenStream = null;
      final camTracks = _localStream?.getVideoTracks() ?? [];
      if (camTracks.isNotEmpty) {
        for (final pc in _peers.values) {
          final sender = _timVideoSender(await pc.getSenders());
          await sender?.replaceTrack(camTracks.first);
        }
        _localRenderer.srcObject = _localStream;
      }
      final targetIds = widget.nguoiThamGia.map((n) => n.id).toList();
      _socket.gui({'type': 'rtc_screen_share_stop', 'data': {'target_ids': targetIds, 'call_id': widget.callId}});
      setState(() => _screenSharing = false);
    }
  }

  Future<void> _ketThucCuocGoi() async {
    for (final id in _peers.keys.toList()) {
      _socket.gui({'type': 'rtc_call_leave', 'data': {'target_id': id, 'call_id': widget.callId}});
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _donDep() async {
    _sub?.cancel();
    for (final pc in _peers.values) {
      await pc.close();
    }
    for (final r in _remoteRenderers.values) {
      await r.dispose();
    }
    await _localRenderer.dispose();
    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _localStream?.dispose();
    for (final track in _screenStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _screenStream?.dispose();
  }

  @override
  void dispose() {
    _donDep();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(children: [
          if (_dangKetNoi)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_remoteRenderers.isEmpty)
            const Center(child: Text('Đang chờ người khác tham gia...', style: TextStyle(color: Colors.white70)))
          else
            GridView.count(
              crossAxisCount: _remoteRenderers.length > 1 ? 2 : 1,
              children: _remoteRenderers.entries.map((e) => Stack(
                fit: StackFit.expand,
                children: [
                  RTCVideoView(e.value, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                  Positioned(
                    left: 8, bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                      child: Text(_tenNguoiThamGia(e.key), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              )).toList(),
            ),

          Positioned(
            right: 16, top: 16, width: 160, height: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            ),
          ),

          Positioned(
            bottom: 24, left: 0, right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _nutDieuKhien(_micOn ? Icons.mic : Icons.mic_off, _toggleMic),
              const SizedBox(width: 16),
              _nutDieuKhien(_camOn ? Icons.videocam : Icons.videocam_off, _toggleCam),
              const SizedBox(width: 16),
              _nutDieuKhien(_screenSharing ? Icons.stop_screen_share : Icons.screen_share, _toggleScreenShare),
              const SizedBox(width: 16),
              _nutDieuKhien(Icons.call_end, _ketThucCuocGoi, mau: Colors.redAccent),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _nutDieuKhien(IconData icon, VoidCallback onTap, {Color mau = Colors.white24}) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 52, height: 52,
      decoration: BoxDecoration(color: mau, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white),
    ),
  );
}
