import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/format_tien.dart';
import '../../core/theme.dart';
import 'lenh_nhanh_model.dart';
import 'lenh_nhanh_provider.dart';

// ── Entry point ──────────────────────────────────────────────────────────────

Future<int?> moLenhNhanhDialog(BuildContext context) {
  return showDialog<int>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (_) => const LenhNhanhDialog(),
  );
}

// ── Dialog ───────────────────────────────────────────────────────────────────

class LenhNhanhDialog extends ConsumerStatefulWidget {
  const LenhNhanhDialog({super.key});

  @override
  ConsumerState<LenhNhanhDialog> createState() => _LenhNhanhDialogState();
}

class _LenhNhanhDialogState extends ConsumerState<LenhNhanhDialog> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  final _chatScroll = ScrollController();

  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _dangNghe = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(phienLenhNhanhProvider.notifier).datLai();
      _focusNode.requestFocus();
    });
    _initSpeech();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final ok = await _speech.initialize();
      if (mounted) setState(() => _speechAvailable = ok);
    } catch (_) {}
  }

  void _gui() {
    final lenh = _ctrl.text.trim();
    if (lenh.isEmpty || ref.read(phienLenhNhanhProvider).dangTai) return;
    _ctrl.clear();
    ref.read(phienLenhNhanhProvider.notifier).guiLenh(lenh);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _batDauNghe() async {
    if (!_speechAvailable || _dangNghe) return;
    setState(() => _dangNghe = true);
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _ctrl.text = result.recognizedWords;
          setState(() => _dangNghe = false);
          _focusNode.requestFocus();
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: 'vi_VN',
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _dungNghe() async {
    await _speech.stop();
    setState(() => _dangNghe = false);
  }

  Future<void> _taoDon() async {
    try {
      final id = await ref.read(phienLenhNhanhProvider.notifier).taoDon();
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo đơn: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(phienLenhNhanhProvider);

    ref.listen(phienLenhNhanhProvider, (prev, next) {
      if ((prev?.lichSu.length ?? 0) != next.lichSu.length) {
        _scrollToBottom();
      }
    });

    return Dialog(
      backgroundColor: const Color(0xFFF8F9FA),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 660,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(st),
            Flexible(child: _buildChat(st)),
            if (st.gio.isNotEmpty || st.tenKhach != 'Khách lẻ') _buildGio(st),
            if (st.canhBao.isNotEmpty) _buildCanhBao(st.canhBao),
            _buildInput(st),
            _buildChips(st),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(PhienLenhNhanh st) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: Color(0xFFE8E8E8))),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.navSelected.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bolt, size: 18, color: AppColors.navSelected),
        ),
        const SizedBox(width: 10),
        const Text('Lệnh nhanh',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const Spacer(),
        if (st.coTheHoanTac && !st.dangTai)
          TextButton.icon(
            onPressed: () => ref.read(phienLenhNhanhProvider.notifier).hoanTac(),
            icon: const Icon(Icons.undo, size: 16),
            label: const Text('Hoàn tác', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
          color: AppColors.textSecondary,
        ),
      ]),
    );
  }

  // ── Chat ────────────────────────────────────────────────────────────────────

  Widget _buildChat(PhienLenhNhanh st) {
    if (st.lichSu.isEmpty) return _buildChatEmpty();
    return ListView.builder(
      controller: _chatScroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: st.lichSu.length + (st.dangTai ? 1 : 0),
      itemBuilder: (_, i) {
        if (st.dangTai && i == st.lichSu.length) return _BubbleDangTai();
        return _BubbleTinNhan(tinNhan: st.lichSu[i]);
      },
    );
  }

  Widget _buildChatEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 36,
              color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text('Nhập lệnh để bắt đầu',
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text(
            '"chị Mai 2 dép đỏ 37"\n'
            '"thêm 1 sandal trắng 38"\n'
            '"bỏ dép ra" · "đổi thành chị Lan"',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.7),
          ),
        ],
      ),
    );
  }

  // ── Giỏ hàng ────────────────────────────────────────────────────────────────

  Widget _buildGio(PhienLenhNhanh st) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE8E8E8)),
          bottom: BorderSide(color: Color(0xFFE8E8E8)),
        ),
      ),
      constraints: const BoxConstraints(maxHeight: 220),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tên khách
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(children: [
              const Icon(Icons.person_outline,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(st.tenKhach,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              if (st.khachHangId != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.activeGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Khách quen',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.activeGreen)),
                ),
              ],
            ]),
          ),
          // Danh sách mặt hàng
          if (st.gio.isNotEmpty)
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: st.gio
                      .map((m) => _MatHangRow(
                            matHang: m,
                            onTangSL: () => ref
                                .read(phienLenhNhanhProvider.notifier)
                                .suaSoLuong(m.bienTheId, m.soLuong + 1),
                            onGiamSL: () => ref
                                .read(phienLenhNhanhProvider.notifier)
                                .suaSoLuong(m.bienTheId, m.soLuong - 1),
                            onXoa: () => ref
                                .read(phienLenhNhanhProvider.notifier)
                                .xoaMatHang(m.bienTheId),
                          ))
                      .toList(),
                ),
              ),
            ),
          // Tổng
          if (st.gio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(children: [
                const Spacer(),
                const Text('Tổng: ',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                Text(dinhDangTien(st.tongTien),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navSelected)),
              ]),
            ),
        ],
      ),
    );
  }

  // ── Cảnh báo ────────────────────────────────────────────────────────────────

  Widget _buildCanhBao(List<String> canhBao) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: canhBao
            .map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠ ',
                          style:
                              TextStyle(color: Colors.orange, fontSize: 12)),
                      Expanded(
                        child: Text(w,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.orange)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Input ────────────────────────────────────────────────────────────────────

  Widget _buildInput(PhienLenhNhanh st) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      color: Colors.white,
      child: Row(children: [
        // Mic
        if (_speechAvailable)
          GestureDetector(
            onTap: _dangNghe ? _dungNghe : _batDauNghe,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _dangNghe
                    ? Colors.red.shade50
                    : const Color(0xFFF0F0F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _dangNghe ? Icons.stop : Icons.mic_none,
                size: 20,
                color: _dangNghe ? Colors.red : AppColors.textSecondary,
              ),
            ),
          ),
        if (_speechAvailable) const SizedBox(width: 8),
        // Text field
        Expanded(
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            enabled: !st.dangTai,
            decoration: InputDecoration(
              hintText: _dangNghe
                  ? 'Đang nghe...'
                  : 'Nhập lệnh (vd: thêm 2 sandal đỏ 38)',
              hintStyle: TextStyle(
                color: _dangNghe
                    ? Colors.red.shade300
                    : AppColors.textSecondary,
                fontSize: 13,
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              suffixIcon: ValueListenableBuilder(
                valueListenable: _ctrl,
                builder: (context, val, child) => val.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: _ctrl.clear,
                        color: AppColors.textSecondary,
                        padding: EdgeInsets.zero,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            onSubmitted: (_) => _gui(),
            textInputAction: TextInputAction.send,
          ),
        ),
        const SizedBox(width: 8),
        // Gửi
        GestureDetector(
          onTap: st.dangTai ? null : _gui,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: st.dangTai
                  ? const Color(0xFFE0E0E0)
                  : AppColors.navSelected,
              shape: BoxShape.circle,
            ),
            child: st.dangTai
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded,
                    size: 18, color: Colors.white),
          ),
        ),
      ]),
    );
  }

  // ── Chips ────────────────────────────────────────────────────────────────────

  Widget _buildChips(PhienLenhNhanh st) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      color: Colors.white,
      child: Row(children: [
        if (st.gio.isNotEmpty || st.lichSu.isNotEmpty)
          _QuickChip(
            nhan: 'Làm lại',
            icon: Icons.refresh,
            mau: Colors.orange.shade700,
            mauNen: Colors.orange.shade50,
            onNhan: st.dangTai
                ? null
                : () => ref.read(phienLenhNhanhProvider.notifier).datLai(),
          ),
        const Spacer(),
        if (st.gio.isNotEmpty)
          _QuickChip(
            nhan:
                st.sanSangTaoDon ? '✓ Xác nhận tạo đơn' : 'Tạo đơn',
            icon: st.sanSangTaoDon
                ? Icons.check_circle
                : Icons.shopping_cart_checkout,
            mau: Colors.white,
            mauNen: st.sanSangTaoDon
                ? AppColors.activeGreen
                : AppColors.navSelected,
            onNhan: st.dangTai ? null : _taoDon,
          ),
      ]),
    );
  }
}

// ── Bubble: tin nhắn ──────────────────────────────────────────────────────────

class _BubbleTinNhan extends StatelessWidget {
  final TinNhan tinNhan;

  const _BubbleTinNhan({required this.tinNhan});

  @override
  Widget build(BuildContext context) {
    final isUser = tinNhan.laNguoiDung;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.navSelected.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt,
                  size: 15, color: AppColors.navSelected),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.navSelected : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                tinNhan.noiDung,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 34),
        ],
      ),
    );
  }
}

// ── Bubble: đang tải ──────────────────────────────────────────────────────────

class _BubbleDangTai extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.navSelected.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bolt, size: 15, color: AppColors.navSelected),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const SizedBox(
            width: 44,
            height: 4,
            child: LinearProgressIndicator(
              backgroundColor: Color(0xFFE0E0E0),
              color: AppColors.textSecondary,
              minHeight: 3,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Dòng mặt hàng ────────────────────────────────────────────────────────────

class _MatHangRow extends StatelessWidget {
  final MatHangXemTruoc matHang;
  final VoidCallback onTangSL;
  final VoidCallback onGiamSL;
  final VoidCallback onXoa;

  const _MatHangRow({
    required this.matHang,
    required this.onTangSL,
    required this.onGiamSL,
    required this.onXoa,
  });

  @override
  Widget build(BuildContext context) {
    final m = matHang;
    final tenDay = [m.tenSanPham, m.mauSac, m.kichCo]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 3, 8, 3),
      child: Row(children: [
        Expanded(
          child: Text(tenDay,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        _SlButton(icon: Icons.remove, onTap: onGiamSL),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('${m.soLuong}',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        _SlButton(icon: Icons.add, onTap: onTangSL),
        const SizedBox(width: 8),
        SizedBox(
          width: 76,
          child: Text(dinhDangTien(m.thanhTien),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 15),
          onPressed: onXoa,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          color: Colors.red.shade300,
        ),
      ]),
    );
  }
}

class _SlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }
}

// ── Quick chip ────────────────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final String nhan;
  final IconData icon;
  final Color mau;
  final Color mauNen;
  final VoidCallback? onNhan;

  const _QuickChip({
    required this.nhan,
    required this.icon,
    required this.mau,
    required this.mauNen,
    required this.onNhan,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onNhan,
      icon: Icon(icon, size: 15, color: mau),
      label: Text(nhan,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: mau)),
      style: ElevatedButton.styleFrom(
        backgroundColor: mauNen,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        disabledBackgroundColor: const Color(0xFFE8E8E8),
      ),
    );
  }
}
