import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/phien_lam_viec.dart';
import 'xac_thuc_provider.dart';

class DangNhapPage extends ConsumerStatefulWidget {
  const DangNhapPage({super.key});

  @override
  ConsumerState<DangNhapPage> createState() => _DangNhapPageState();
}

class _DangNhapPageState extends ConsumerState<DangNhapPage> {
  final _tenCtrl = TextEditingController();
  final _soDtCtrl = TextEditingController();
  String _pinNhap = '';
  String? _loi;
  bool _dangTai = false;

  @override
  void dispose() {
    _tenCtrl.dispose();
    _soDtCtrl.dispose();
    super.dispose();
  }

  void _nhanPhim(String kyTu, PhienLamViec? phienCu) {
    if (_pinNhap.length >= 4 || _dangTai) return;
    setState(() {
      _pinNhap += kyTu;
      _loi = null;
    });
    if (_pinNhap.length == 4) {
      _xacNhan(phienCu);
    }
  }

  void _xoaPhim() {
    if (_pinNhap.isEmpty || _dangTai) return;
    setState(() => _pinNhap = _pinNhap.substring(0, _pinNhap.length - 1));
  }

  Future<void> _xacNhan(PhienLamViec? phienCu) async {
    setState(() { _loi = null; _dangTai = true; });
    final notifier = ref.read(xacThucProvider.notifier);
    try {
      if (phienCu != null) {
        // Đã có session → chỉ kiểm tra PIN
        await notifier.dangNhapBangPin(_pinNhap);
      } else {
        // Không có session → cần số điện thoại (+ tên nếu số mới)
        final soDt = _soDtCtrl.text.trim();
        if (soDt.isEmpty) {
          setState(() { _loi = 'Vui lòng nhập số điện thoại'; _pinNhap = ''; _dangTai = false; });
          return;
        }
        final ten = _tenCtrl.text.trim(); // backend bỏ qua nếu số đã tồn tại
        await notifier.dangKyHoacDangNhap(ten: ten, soDienThoai: soDt, pin: _pinNhap);
      }
    } catch (e) {
      final thongBao = _docLoi(e);
      setState(() { _loi = thongBao; _pinNhap = ''; _dangTai = false; });
    }
  }

  String _docLoi(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      if (status == 401) return 'PIN không đúng';
      if (status == 403) return 'Tài khoản đang bị khóa';
      if (data is Map && data['detail'] != null) return data['detail'].toString();
    }
    return 'Lỗi kết nối, thử lại';
  }

  @override
  Widget build(BuildContext context) {
    final phien = ref.watch(xacThucProvider).valueOrNull;
    return _buildBody(phien);
  }

  Widget _buildBody(PhienLamViec? phien) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: phien == null ? _buildLanDau() : _buildQuayLai(phien),
        ),
      ),
    );
  }

  // ── Lần đầu / số mới ───────────────────────────────────────────────────────

  Widget _buildLanDau() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text('FISD', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 6),
        const Text('Nhập số điện thoại để bắt đầu', style: TextStyle(fontSize: 15, color: Colors.grey)),
        const SizedBox(height: 40),
        _oNhap(
          controller: _soDtCtrl,
          nhanGoi: 'Số điện thoại *',
          icon: Icons.phone_outlined,
          loaiBanPhim: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _oNhap(
          controller: _tenCtrl,
          nhanGoi: 'Tên (chỉ cần nếu số chưa đăng ký)',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 28),
        const Text('Mã PIN (4 chữ số)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 16),
        _dotPin(),
        const SizedBox(height: 28),
        if (_loi != null) _loiWidget(),
        if (_dangTai)
          const Center(child: CircularProgressIndicator())
        else
          _banPhimSo(null),
      ],
    );
  }

  // ── Quay lại: chỉ PIN ───────────────────────────────────────────────────────

  Widget _buildQuayLai(PhienLamViec phien) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        CircleAvatar(
          radius: 36,
          backgroundColor: const Color(0xFF1A1A2E),
          child: Text(
            phien.ten.isNotEmpty ? phien.ten[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        Text('Xin chào, ${phien.ten}!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(phien.soDienThoai, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 36),
        const Text('Nhập mã PIN', style: TextStyle(fontSize: 15, color: Colors.grey)),
        const SizedBox(height: 20),
        _dotPin(),
        const SizedBox(height: 28),
        if (_loi != null) _loiWidget(),
        if (_dangTai)
          const Center(child: CircularProgressIndicator())
        else
          _banPhimSo(phien),
        const SizedBox(height: 24),
        TextButton(
          onPressed: _dangTai ? null : () async {
            await ref.read(xacThucProvider.notifier).dangXuat();
            setState(() { _pinNhap = ''; _loi = null; });
          },
          child: const Text('Đổi tài khoản', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  // ── Widgets dùng chung ─────────────────────────────────────────────────────

  Widget _oNhap({
    required TextEditingController controller,
    required String nhanGoi,
    required IconData icon,
    TextInputType loaiBanPhim = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: loaiBanPhim,
      enabled: !_dangTai,
      inputFormatters: loaiBanPhim == TextInputType.phone ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: InputDecoration(
        hintText: nhanGoi,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _dotPin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final diaDiem = i < _pinNhap.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: diaDiem ? const Color(0xFF1A1A2E) : Colors.transparent,
            border: Border.all(
              color: diaDiem ? const Color(0xFF1A1A2E) : Colors.grey.shade400,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _loiWidget() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_loi!, style: const TextStyle(color: Colors.red, fontSize: 14))),
          ],
        ),
      ),
    );
  }

  Widget _banPhimSo(PhienLamViec? phien) {
    final phimSo = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: phimSo.length,
      itemBuilder: (_, i) {
        final nhan = phimSo[i];
        if (nhan.isEmpty) return const SizedBox();
        final laXoa = nhan == '⌫';
        return Material(
          color: laXoa ? Colors.grey.shade200 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: laXoa ? _xoaPhim : () => _nhanPhim(nhan, phien),
            child: Center(
              child: Text(
                nhan,
                style: TextStyle(
                  fontSize: laXoa ? 22 : 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
