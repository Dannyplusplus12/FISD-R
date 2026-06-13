import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'xac_thuc_provider.dart';

class DangNhapPage extends ConsumerStatefulWidget {
  const DangNhapPage({super.key});

  @override
  ConsumerState<DangNhapPage> createState() => _DangNhapPageState();
}

class _DangNhapPageState extends ConsumerState<DangNhapPage>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _rungController;
  late Animation<double> _rungAnimation;

  @override
  void initState() {
    super.initState();
    _rungController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rungAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rungController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _rungController.dispose();
    super.dispose();
  }

  void _nhapChuSo(String cs) {
    if (_pin.length >= 4) return;
    final tiep = _pin + cs;
    setState(() => _pin = tiep);
    if (tiep.length == 4) _guiDangNhap();
  }

  void _xoa() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _guiDangNhap() async {
    final ok = await ref.read(xacThucProvider.notifier).dangNhapPin(pin: _pin);
    if (!ok && mounted) {
      _rungController.forward(from: 0);
      setState(() => _pin = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dangTai = ref.watch(xacThucProvider).isLoading;
    final kichThuoc = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 360, minHeight: kichThuoc.height * 0.8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Logo(),
                    const SizedBox(height: 48),
                    _HienThiPin(pin: _pin, rungAnimation: _rungAnimation),
                    const SizedBox(height: 40),
                    if (dangTai)
                      const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator(color: Colors.white54)),
                      )
                    else
                      _BanPhim(nhapChuSo: _nhapChuSo, xoa: _xoa),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          ),
          child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        const Text(
          'FISD',
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 4),
        ),
        const SizedBox(height: 4),
        Text(
          'Quản lý kho hàng',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, letterSpacing: 1),
        ),
      ],
    );
  }
}

class _HienThiPin extends StatelessWidget {
  final String pin;
  final Animation<double> rungAnimation;

  const _HienThiPin({required this.pin, required this.rungAnimation});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Nhập mã PIN',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, letterSpacing: 0.5)),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: rungAnimation,
          builder: (_, child) {
            final dx = rungAnimation.value == 0
                ? 0.0
                : 8.0 * (0.5 - rungAnimation.value).abs() * (rungAnimation.value < 0.5 ? 1 : -1);
            return Transform.translate(offset: Offset(dx * 4, 0), child: child);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final daDien = i < pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: daDien ? 20 : 16,
                height: daDien ? 20 : 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: daDien ? Colors.white : Colors.white.withOpacity(0.2),
                  border: daDien ? null : Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _BanPhim extends StatelessWidget {
  final ValueChanged<String> nhapChuSo;
  final VoidCallback xoa;

  const _BanPhim({required this.nhapChuSo, required this.xoa});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final hang in [['1','2','3'], ['4','5','6'], ['7','8','9'], ['','0','⌫']])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: hang.map((k) {
                if (k.isEmpty) return const SizedBox(width: 80, height: 80);
                return _Phim(nhan: k, laXoa: k == '⌫', onNhan: () => k == '⌫' ? xoa() : nhapChuSo(k));
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _Phim extends StatefulWidget {
  final String nhan;
  final bool laXoa;
  final VoidCallback onNhan;

  const _Phim({required this.nhan, required this.onNhan, this.laXoa = false});

  @override
  State<_Phim> createState() => _PhimState();
}

class _PhimState extends State<_Phim> {
  bool _nhanXuong = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _nhanXuong = true),
      onTapUp: (_) { setState(() => _nhanXuong = false); widget.onNhan(); },
      onTapCancel: () => setState(() => _nhanXuong = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _nhanXuong ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(_nhanXuong ? 0.5 : 0.15), width: 1),
          ),
          child: Center(
            child: widget.laXoa
                ? Icon(Icons.backspace_outlined, color: Colors.white.withOpacity(0.8), size: 22)
                : Text(widget.nhan,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w400)),
          ),
        ),
      ),
    );
  }
}
