import 'dart:io';
import 'package:fisd_shared/fisd_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import 'san_pham_orderer_provider.dart';

// FormSanPhamPage — tạo / sửa sản phẩm (standalone fullscreen page)

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
          .map((bt) => _BienTheEdit(
                id: bt.id,
                mauSac: bt.mauSac,
                kichCo: bt.kichCo,
                gia: bt.gia,
                tonKho: bt.tonKho,
              ))
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

  Future<void> _chupAnh() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _localImagePath = picked.path;
      _uploadingAnh = true;
    });
    try {
      final key =
          await ref.read(sanPhamOrdererRepoProvider).uploadAnh(picked.path, picked.name);
      if (mounted) setState(() { _imagePath = key; _uploadingAnh = false; });
    } catch (_) {
      if (mounted) setState(() => _uploadingAnh = false);
    }
  }

  void _themBienThe() {
    setState(() => _bienThes.add(_BienTheEdit(mauSac: '', kichCo: '', gia: 0, tonKho: 0)));
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
              id: widget.edit!.id,
              ten: ten,
              ma: _maCtrl.text.trim(),
              imagePath: _imagePath,
              bienThes: bts,
            );
      } else {
        await ref.read(sanPhamOrdererRepoProvider).taoSanPham(
              ten: ten,
              ma: _maCtrl.text.trim(),
              imagePath: _imagePath,
              bienThes: bts,
            );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.edit != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _luu,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Lưu',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Ảnh sản phẩm
        GestureDetector(
          onTap: _chupAnh,
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: _uploadingAnh
                ? const Center(child: CircularProgressIndicator())
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildAnhPreview(),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        // Thông tin cơ bản
        Container(
          decoration: AppDeco.card(),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
                controller: _tenCtrl,
                decoration: AppDeco.input('Tên sản phẩm *', icon: Icons.label_outline)),
            const SizedBox(height: 10),
            TextField(
                controller: _maCtrl,
                decoration: AppDeco.input('Mã sản phẩm', icon: Icons.qr_code_outlined)),
          ]),
        ),
        const SizedBox(height: 16),
        // Biến thể header
        Row(children: [
          const Text('Biến thể', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          TextButton.icon(
            onPressed: _themBienThe,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm'),
          ),
        ]),
        const SizedBox(height: 8),
        ..._bienThes.asMap().entries.map((e) => _BienTheForm(
              key: ValueKey(e.key),
              data: e.value,
              onRemove: () => setState(() => _bienThes.removeAt(e.key)),
            )),
        if (_bienThes.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppDeco.card(),
            child: const Center(
              child: Text(
                'Chưa có biến thể nào.\nNhấn "Thêm" để tạo biến thể.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _buildAnhPreview() {
    if (_localImagePath != null) {
      return Image.file(File(_localImagePath!), fit: BoxFit.cover, width: double.infinity);
    }
    if (_imagePath.isNotEmpty && widget.edit?.anh.isNotEmpty == true) {
      return Image.network(widget.edit!.anh, fit: BoxFit.cover, width: double.infinity,
          errorBuilder: (_, __, ___) => _anhPlaceholder());
    }
    return _anhPlaceholder();
  }

  Widget _anhPlaceholder() => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.textSecondary),
          SizedBox(height: 8),
          Text('Nhấn để chọn ảnh', style: TextStyle(color: AppColors.textSecondary)),
        ],
      );
}

class _BienTheEdit {
  final int? id;
  String mauSac;
  String kichCo;
  int gia;
  int tonKho;

  _BienTheEdit({
    this.id,
    required this.mauSac,
    required this.kichCo,
    required this.gia,
    required this.tonKho,
  });
}

class _BienTheForm extends StatefulWidget {
  final _BienTheEdit data;
  final VoidCallback onRemove;
  const _BienTheForm({super.key, required this.data, required this.onRemove});

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
    _giaCtrl = TextEditingController(text: widget.data.gia > 0 ? '${widget.data.gia ~/ 1000}' : '');
    _slCtrl = TextEditingController(text: '${widget.data.tonKho}');
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

  @override
  Widget build(BuildContext context) {
    final label = widget.data.id != null ? 'Biến thể #${widget.data.id}' : 'Biến thể mới';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDeco.card(),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          GestureDetector(
              onTap: widget.onRemove,
              child: const Icon(Icons.close, size: 18, color: AppColors.danger)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _mauCtrl,
                  onChanged: (_) => _sync(),
                  decoration: AppDeco.input('Màu sắc'))),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(
                  controller: _coCtrl,
                  onChanged: (_) => _sync(),
                  decoration: AppDeco.input('Kích cỡ'))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _giaCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => _sync(),
                  decoration: const InputDecoration(labelText: 'Giá (k) *', suffixText: 'k'))),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(
                  controller: _slCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => _sync(),
                  decoration:
                      AppDeco.input('Tồn kho', icon: Icons.warehouse_outlined))),
        ]),
      ]),
    );
  }
}
