import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format_tien.dart';
import '../../core/theme.dart';
import '../don_hang/don_hang_provider.dart';
import 'lenh_nhanh_provider.dart';
import 'lenh_nhanh_model.dart';

class LenhNhanhDialog extends ConsumerStatefulWidget {
  const LenhNhanhDialog({super.key});

  @override
  ConsumerState<LenhNhanhDialog> createState() => _LenhNhanhDialogState();
}

class _LenhNhanhDialogState extends ConsumerState<LenhNhanhDialog> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lenhNhanhProvider.notifier).datLai();
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _phanTich() {
    final lenh = _ctrl.text.trim();
    if (lenh.isEmpty) return;
    ref.read(lenhNhanhProvider.notifier).phanTich(lenh);
  }

  void _taoDon() {
    ref.read(lenhNhanhProvider.notifier).taoDon();
  }

  @override
  Widget build(BuildContext context) {
    final tt = ref.watch(lenhNhanhProvider);

    ref.listen(lenhNhanhProvider, (prev, next) {
      if (next.trangThai == TrangThaiLenh.xong) {
        ref.read(quanLyDonHangProvider.notifier).lamMoi();
        ref.read(donHangChoProvider.notifier).lamMoi();
        Navigator.of(context).pop(next.donId);
      }
    });

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Icon(Icons.bolt, size: 20),
                const SizedBox(width: 8),
                const Text('Lệnh nhanh',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    enabled: !tt.dangTai,
                    decoration: InputDecoration(
                      hintText: 'vd: chị Mai 1 đôi longden đen 40',
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _phanTich(),
                  ),
                ),
                const SizedBox(width: 8),
                _NutHanhDong(
                  nhan: 'Phân tích',
                  mau: AppColors.navSelected,
                  dangTai: tt.trangThai == TrangThaiLenh.dangGoiAI ||
                      tt.trangThai == TrangThaiLenh.dangTimDB,
                  onNhan: tt.dangTai ? null : _phanTich,
                ),
              ]),

              if (tt.dangTai && tt.nhanTrangThai.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(children: [
                  const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(tt.nhanTrangThai,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ]),
              ],

              if (tt.trangThai == TrangThaiLenh.xemTruoc ||
                  tt.trangThai == TrangThaiLenh.dangTao) ...[
                const SizedBox(height: 20),
                _XemTruocWidget(
                  ketQua: tt.ketQua!,
                  dangTao: tt.trangThai == TrangThaiLenh.dangTao,
                  onTaoDon: _taoDon,
                  onSua: () {
                    ref.read(lenhNhanhProvider.notifier).datLai();
                    _focus.requestFocus();
                  },
                ),
              ],

              if (tt.trangThai == TrangThaiLenh.loi) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tt.thongBaoLoi ?? 'Lỗi không xác định',
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _XemTruocWidget extends StatelessWidget {
  final KetQuaLenhNhanh ketQua;
  final bool dangTao;
  final VoidCallback onTaoDon;
  final VoidCallback onSua;

  const _XemTruocWidget({
    required this.ketQua,
    required this.dangTao,
    required this.onTaoDon,
    required this.onSua,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(ketQua.tenKhach,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (ketQua.khachHangId != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.activeGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Khách quen',
                    style: TextStyle(fontSize: 10, color: AppColors.activeGreen)),
              ),
            ],
          ]),
          if (ketQua.gio.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...ketQua.gio.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        '${m.tenSanPham}'
                        '${m.mauSac.isNotEmpty ? " · ${m.mauSac}" : ""}'
                        '${m.kichCo.isNotEmpty ? " · ${m.kichCo}" : ""}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('×${m.soLuong}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    Text(dinhDangTien(m.thanhTien),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                )),
            const Divider(height: 16),
            Row(children: [
              const Spacer(),
              const Text('Tổng: ',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(dinhDangTien(ketQua.tongTien),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.navSelected)),
            ]),
          ],
        ]),
      ),

      if (ketQua.canhBao.isNotEmpty) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ketQua.canhBao
                .map((w) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('⚠ ',
                          style: TextStyle(color: Colors.orange, fontSize: 12)),
                      Expanded(
                        child: Text(w,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.orange)),
                      ),
                    ]))
                .toList(),
          ),
        ),
      ],

      const SizedBox(height: 14),
      Row(children: [
        OutlinedButton(
          onPressed: dangTao ? null : onSua,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Sửa lệnh'),
        ),
        const Spacer(),
        if (ketQua.gio.isNotEmpty)
          _NutHanhDong(
            nhan: 'Tạo đơn',
            mau: AppColors.activeGreen,
            dangTai: dangTao,
            onNhan: dangTao ? null : onTaoDon,
          ),
      ]),
    ]);
  }
}

class _NutHanhDong extends StatelessWidget {
  final String nhan;
  final Color mau;
  final bool dangTai;
  final VoidCallback? onNhan;

  const _NutHanhDong({
    required this.nhan,
    required this.mau,
    this.dangTai = false,
    required this.onNhan,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onNhan,
      style: ElevatedButton.styleFrom(
        backgroundColor: mau,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      child: dangTai
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Text(nhan, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

Future<int?> moLenhNhanhDialog(BuildContext context) {
  return showDialog<int>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const LenhNhanhDialog(),
  );
}
