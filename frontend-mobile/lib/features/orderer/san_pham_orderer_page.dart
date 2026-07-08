import 'dart:io';
import 'package:fisd_shared/fisd_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import 'san_pham_orderer_provider.dart';

class FormSanPhamPage extends ConsumerStatefulWidget {
  final SanPham? edit;
  const FormSanPhamPage({super.key, this.edit});

  @override
  ConsumerState<FormSanPhamPage> createState() => _FormSanPhamPageState();
}

class _FormSanPhamPageState extends ConsumerState<FormSanPhamPage> {
  final _tenCtrl = TextEditingController();
  final _maCtrl = TextEditingController();
  String _imagePath = '';
  String? _localImagePath;
  bool _uploadingAnh = false;
  bool _saving = false;
  late List<_BienTheEdit> _bienThes;

  @override
  void initState() {
    super.initState();
    final sp = widget.edit;
    if (sp != null) {
      _tenCtrl.text = sp.ten;
      _maCtrl.text = sp.ma;
      _imagePath = sp.anhKey;
      _bienThes = sp.bienThes
          .map((bt) => _BienTheEdit(id: bt.id, mauSac: bt.mauSac, kichCo: bt.kichCo, gia: bt.gia, tonKho: bt.tonKho))
          .toList();
    } else {
      _bienThes = [];
    }
  }

  @override
  void dispose() {
    _tenCtrl.dispose();
    _maCtrl.dispose();
    super.dispose();
  }

  Future<void> _chonAnh() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() { _localImagePath = picked.path; _uploadingAnh = true; });
    try {
      final key = await ref.read(sanPhamOrdererRepoProvider).uploadAnh(picked.path, picked.name);
      if (mounted) setState(() { _imagePath = key; _uploadingAnh = false; });
    } catch (_) {
      if (mounted) setState(() => _uploadingAnh = false);
    }
  }

  Future<void> _luu() async {
    final ten = _tenCtrl.text.trim();
    if (ten.isEmpty) return;
    setState(() => _saving = true);
    try {
      final bts = _bienThes
          .where((bt) => bt.gia > 0)
          .map((bt) => {
                if (bt.id != null) 'id': bt.id,
                'color': bt.mauSac,
                'size': bt.kichCo,
                'price': bt.gia,
                'stock': bt.tonKho,
              })
          .toList();
      if (widget.edit != null) {
        await ref.read(sanPhamOrdererRepoProvider).capNhatSanPham(
            id: widget.edit!.id, ten: ten, ma: _maCtrl.text.trim(),
            imagePath: _imagePath, bienThes: bts);
      } else {
        await ref.read(sanPhamOrdererRepoProvider).taoSanPham(
            ten: ten, ma: _maCtrl.text.trim(),
            imagePath: _imagePath, bienThes: bts);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.edit != null ? 'Sửa sản phẩm' : 'Thêm sản phẩm',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.divider)),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : TextButton(
                  onPressed: _luu,
                  child: const Text('Lưu',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _AnhPicker(
          localPath: _localImagePath,
          networkUrl: widget.edit?.anh ?? '',
          uploading: _uploadingAnh,
          onTap: _chonAnh,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: AppDeco.card(),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
                controller: _tenCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: AppDeco.input('Tên sản phẩm')),
            const SizedBox(height: 10),
            TextField(
                controller: _maCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: AppDeco.input('Mã hàng')),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          const Text('Biến thể', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(
                () => _bienThes.add(_BienTheEdit(mauSac: '', kichCo: '', gia: 0))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text('Thêm', style: TextStyle(color: Colors.white, fontSize: 13)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        if (_bienThes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppDeco.card(),
            child: const Center(
              child: Text('Chưa có biến thể nào.\nNhấn Thêm để tạo.',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ),
          )
        else
          ..._bienThes.asMap().entries.map((e) => _BienTheForm(
                key: ValueKey(e.key),
                data: e.value,
                index: e.key + 1,
                onRemove: () => setState(() => _bienThes.removeAt(e.key)),
              )),
        const SizedBox(height: 40),
      ]),
    );
  }
}

// ── Ảnh picker ────────────────────────────────────────────────────────────────

class _AnhPicker extends StatelessWidget {
  final String? localPath;
  final String networkUrl;
  final bool uploading;
  final VoidCallback onTap;

  const _AnhPicker({
    required this.localPath,
    required this.networkUrl,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(fit: StackFit.expand, children: [
            if (uploading)
              const Center(child: CircularProgressIndicator())
            else if (localPath != null)
              Image.file(File(localPath!), fit: BoxFit.cover)
            else if (networkUrl.isNotEmpty)
              Image.network(networkUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
            else
              _placeholder(),
            // Edit overlay
            Positioned(
              bottom: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.photo_camera_outlined, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Đổi ảnh', style: TextStyle(color: Colors.white, fontSize: 12)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _placeholder() => const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.divider),
        SizedBox(height: 8),
        Text('Nhấn để chọn ảnh', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ]);
}

// ── Data model biến thể ───────────────────────────────────────────────────────

class _BienTheEdit {
  final int? id;
  String mauSac;
  String kichCo;
  int gia;
  int tonKho;

  _BienTheEdit({this.id, required this.mauSac, required this.kichCo, required this.gia, this.tonKho = 0});
}

// ── Form biến thể ─────────────────────────────────────────────────────────────

class _BienTheForm extends StatefulWidget {
  final _BienTheEdit data;
  final int index;
  final VoidCallback onRemove;
  const _BienTheForm({super.key, required this.data, required this.index, required this.onRemove});

  @override
  State<_BienTheForm> createState() => _BienTheFormState();
}

class _BienTheFormState extends State<_BienTheForm> {
  late final TextEditingController _mauCtrl;
  late final TextEditingController _coCtrl;
  late final TextEditingController _giaCtrl;
  late final TextEditingController _slCtrl;

  @override
  void initState() {
    super.initState();
    _mauCtrl = TextEditingController(text: widget.data.mauSac);
    _coCtrl = TextEditingController(text: widget.data.kichCo);
    _giaCtrl = TextEditingController(
        text: widget.data.gia > 0 ? '${widget.data.gia ~/ 1000}' : '');
    _slCtrl = TextEditingController(
        text: widget.data.tonKho > 0 ? '${widget.data.tonKho}' : '');
  }

  @override
  void dispose() {
    _mauCtrl.dispose();
    _coCtrl.dispose();
    _giaCtrl.dispose();
    _slCtrl.dispose();
    super.dispose();
  }

  void _sync() {
    widget.data.mauSac = _mauCtrl.text.trim();
    widget.data.kichCo = _coCtrl.text.trim();
    widget.data.gia = (int.tryParse(_giaCtrl.text) ?? 0) * 1000;
    widget.data.tonKho = int.tryParse(_slCtrl.text) ?? 0;
  }

  InputDecoration _deco(String label, {String? suffix}) => InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDeco.card(),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Biến thể ${widget.index}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          GestureDetector(
            onTap: widget.onRemove,
            child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _mauCtrl,
                  onChanged: (_) => _sync(),
                  decoration: _deco('Màu sắc'))),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: TextField(
                controller: _coCtrl,
                onChanged: (_) => _sync(),
                decoration: _deco('Size')),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _giaCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _sync(),
              decoration: _deco('Giá', suffix: 'k'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _slCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _sync(),
              decoration: _deco('Số lượng'),
            ),
          ),
        ]),
      ]),
    );
  }
}
