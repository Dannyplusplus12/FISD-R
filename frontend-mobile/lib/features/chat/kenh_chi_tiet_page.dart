import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fisd_shared/fisd_shared.dart';

import '../../core/realtime/realtime_socket.dart';
import '../../core/session/phien_lam_viec.dart';
import '../../core/theme.dart';
import '../../core/thong_bao/da_xem_provider.dart';
import '../../core/thong_bao/dem_chua_doc_provider.dart';
import 'chat_provider.dart';
import 'chat_repository.dart';
import 'goi_video_page.dart';

class KenhChiTietPage extends ConsumerStatefulWidget {
  final KenhChat kenh;
  final PhienLamViec phien;
  const KenhChiTietPage({super.key, required this.kenh, required this.phien});

  @override
  ConsumerState<KenhChiTietPage> createState() => _KenhChiTietPageState();
}

class _KenhChiTietPageState extends ConsumerState<KenhChiTietPage> {
  final _noiDungCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _dangGui = false;
  StreamSubscription? _cuocGoiSub;
  Map<String, dynamic>? _cuocGoiDangDen;

  bool get _laChuKenh => widget.kenh.chuKenhId == widget.phien.id;
  bool get _duocThemNguoi => widget.kenh.laKenhDonHang || _laChuKenh;

  @override
  void initState() {
    super.initState();
    ref.read(demChuaDocProvider.notifier).datKenhDangMo(widget.kenh.id);
    ref.read(demChuaDocProvider.notifier).xoa(widget.kenh.id);
    ref.read(daXemProvider.notifier).danhDauDaXem('kenh_${widget.kenh.id}');
    WidgetsBinding.instance.addPostFrameCallback((_) => _dangKyLangNgheCuocGoi());
  }

  void _dangKyLangNgheCuocGoi() {
    final socket = ref.read(realtimeSocketProvider);
    _cuocGoiSub = socket.messages.listen((msg) {
      if (!mounted) return;
      final data = msg['data'] as Map<String, dynamic>?;
      if (data == null || data['ma_kenh'] != widget.kenh.id) return;
      if (msg['type'] == 'rtc_call_start') {
        setState(() => _cuocGoiDangDen = data);
      }
    });
  }

  List<ThanhVienChat> get _doiPhuong =>
      widget.kenh.thanhVien.where((t) => t.id != widget.phien.id).toList();

  void _batDauGoi({required bool coCamera}) {
    final callId = '${widget.kenh.id}_${DateTime.now().millisecondsSinceEpoch}';
    final targetIds = _doiPhuong.map((t) => t.id).toList();
    ref.read(realtimeSocketProvider).gui({
      'type': 'rtc_call_start',
      'data': {
        'target_ids': targetIds, 'ma_kenh': widget.kenh.id, 'call_id': callId,
        'co_camera': coCamera, 'nguoi_goi': widget.phien.ten,
      },
    });
    Navigator.push(context, MaterialPageRoute(builder: (_) => GoiVideoPage(
      kenhId: widget.kenh.id, callId: callId, nguoiThamGia: _doiPhuong,
      phien: widget.phien, coCamera: coCamera,
    )));
  }

  void _thamGiaCuocGoi() {
    final data = _cuocGoiDangDen;
    if (data == null) return;
    setState(() => _cuocGoiDangDen = null);
    Navigator.push(context, MaterialPageRoute(builder: (_) => GoiVideoPage(
      kenhId: widget.kenh.id, callId: data['call_id'] as String, nguoiThamGia: _doiPhuong,
      phien: widget.phien, coCamera: data['co_camera'] == true,
    )));
  }

  @override
  void dispose() {
    ref.read(demChuaDocProvider.notifier).datKenhDangMo(null);
    _cuocGoiSub?.cancel();
    _noiDungCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _guiText() async {
    final noiDung = _noiDungCtrl.text.trim();
    if (noiDung.isEmpty || _dangGui) return;
    setState(() => _dangGui = true);
    _noiDungCtrl.clear();
    try {
      await ref.read(tinNhanKenhProvider(widget.kenh.id).notifier)
          .gui(nguoiGuiId: widget.phien.id, noiDung: noiDung);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi gửi tin nhắn: $e'), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  Future<void> _guiAnh() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    await _guiFiles(picked.map((x) => MultipartFile.fromFileSync(x.path, filename: x.name)).toList());
  }

  Future<void> _guiTep() async {
    final result = await FilePicker.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;
    final files = result.files
        .where((f) => f.path != null)
        .map((f) => MultipartFile.fromFileSync(f.path!, filename: f.name))
        .toList();
    if (files.isNotEmpty) await _guiFiles(files);
  }

  Future<void> _guiFiles(List<MultipartFile> files) async {
    setState(() => _dangGui = true);
    try {
      await ref.read(tinNhanKenhProvider(widget.kenh.id).notifier).gui(nguoiGuiId: widget.phien.id, files: files);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi gửi tệp: $e'), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  Future<void> _moThemNguoi() async {
    final nhanVienList = await ref.read(danhSachNhanVienProvider.future);
    final daCoIds = widget.kenh.thanhVien.map((t) => t.id).toSet();
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text('Thêm thành viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...nhanVienList.where((nv) => !daCoIds.contains(nv.id)).map((nv) => ListTile(
                title: Text(nv.ten),
                subtitle: Text(nv.nhanVaiTro),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await ref.read(chatRepositoryProvider).themThanhVien(
                          widget.kenh.id,
                          nhanVienId: nv.id,
                          nguoiThemId: widget.phien.id,
                        );
                    ref.invalidate(danhSachKenhProvider(widget.phien.id));
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Đã thêm ${nv.ten} vào kênh')));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger));
                    }
                  }
                },
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mauTieuDe = widget.kenh.laKenhDonHang ? AppColors.warning : AppColors.primary;
    final state = ref.watch(tinNhanKenhProvider(widget.kenh.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.kenh.ten, style: TextStyle(fontWeight: FontWeight.bold, color: mauTieuDe)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined), onPressed: () => _batDauGoi(coCamera: false)),
          IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () => _batDauGoi(coCamera: true)),
          if (_duocThemNguoi)
            IconButton(icon: const Icon(Icons.person_add_alt_outlined), onPressed: _moThemNguoi),
        ],
      ),
      body: Column(children: [
        if (_cuocGoiDangDen != null)
          Container(
            width: double.infinity,
            color: AppColors.info.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              const Icon(Icons.call, color: AppColors.info, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${_cuocGoiDangDen!['nguoi_goi'] ?? 'Ai đó'} đang gọi...',
                    style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w600)),
              ),
              TextButton(onPressed: () => setState(() => _cuocGoiDangDen = null), child: const Text('Bỏ qua')),
              FilledButton(onPressed: _thamGiaCuocGoi, child: const Text('Tham gia')),
            ]),
          ),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => errorState(() => ref.invalidate(tinNhanKenhProvider(widget.kenh.id))),
            data: (list) {
              if (list.isEmpty) return emptyState(Icons.chat_bubble_outline, 'Chưa có tin nhắn nào');
              return ListView.builder(
                controller: _scrollCtrl,
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (_, i) => _TinNhanBubble(
                  tinNhan: list[list.length - 1 - i],
                  laCuaMinh: list[list.length - 1 - i].nguoiGuiId == widget.phien.id,
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.image_outlined), onPressed: _dangGui ? null : _guiAnh),
              IconButton(icon: const Icon(Icons.attach_file), onPressed: _dangGui ? null : _guiTep),
              Expanded(
                child: TextField(
                  controller: _noiDungCtrl,
                  decoration: AppDeco.input('Nhập tin nhắn...'),
                  onSubmitted: (_) => _guiText(),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: _dangGui
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send, color: AppColors.primary),
                onPressed: _dangGui ? null : _guiText,
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _TinNhanBubble extends StatelessWidget {
  final TinNhan tinNhan;
  final bool laCuaMinh;
  const _TinNhanBubble({required this.tinNhan, required this.laCuaMinh});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: laCuaMinh ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: laCuaMinh ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!laCuaMinh)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(tinNhan.tenNguoiGui,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            ),
          if (tinNhan.noiDung.isNotEmpty)
            Text(tinNhan.noiDung, style: TextStyle(color: laCuaMinh ? Colors.white : Colors.black87)),
          for (final tep in tinNhan.tepDinhKem)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: tep.laAnh
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(tep.url, width: 180, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                    )
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.insert_drive_file_outlined,
                          size: 18, color: laCuaMinh ? Colors.white : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(tep.tenGoc,
                            style: TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                                color: laCuaMinh ? Colors.white : Colors.black87)),
                      ),
                    ]),
            ),
          const SizedBox(height: 2),
          Text(tinNhan.thoiGianGui,
              style: TextStyle(
                  fontSize: 10, color: laCuaMinh ? Colors.white70 : AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
