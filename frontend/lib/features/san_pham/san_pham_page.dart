import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../core/format_tien.dart';
import '../../models/san_pham.dart';
import 'san_pham_provider.dart';
import 'san_pham_repository.dart';

class SanPhamPage extends ConsumerStatefulWidget {
  const SanPhamPage({super.key});

  @override
  ConsumerState<SanPhamPage> createState() => _SanPhamPageState();
}

class _SanPhamPageState extends ConsumerState<SanPhamPage> {
  final _timKiemCtrl = TextEditingController();

  @override
  void dispose() {
    _timKiemCtrl.dispose();
    super.dispose();
  }

  Future<String> _taiAnhLen(File? anhFile) async {
    if (anhFile == null) return '';
    return ref.read(sanPhamRepositoryProvider).taiAnhLen(anhFile);
  }

  void _showDialogSanPham(BuildContext context, {SanPham? sanPham}) {
    final tenCtrl = TextEditingController(text: sanPham?.ten ?? '');
    final maCtrl = TextEditingController(text: sanPham?.ma ?? '');
    final variants = List<BienThe>.from(
      sanPham?.bienThes ??
          const [BienThe(mauSac: '', kichCo: '', gia: 0, tonKho: 0)],
    );
    File? anhChon;
    bool dangLuu = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                sanPham == null
                    ? 'Thêm mẫu sản phẩm'
                    : 'Chỉnh sửa mẫu sản phẩm',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ô ảnh preview — nhấn để chọn ảnh mới
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            if (image != null) {
                              setDialogState(() => anhChon = File(image.path));
                            }
                          },
                          child: _OAnhChonAnh(
                            anhFile: anhChon,
                            urlAnh: sanPham?.anh,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tenCtrl,
                        decoration: const InputDecoration(labelText: 'Tên mẫu'),
                      ),
                      TextField(
                        controller: maCtrl,
                        decoration: const InputDecoration(labelText: 'Mã mẫu'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Biến thể',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => setDialogState(() {
                              variants.add(
                                const BienThe(
                                  mauSac: '',
                                  kichCo: '',
                                  gia: 0,
                                  tonKho: 0,
                                ),
                              );
                            }),
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm màu/size'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(variants.length, (index) {
                        final item = variants[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: TextEditingController(
                                              text: item.mauSac,
                                            )
                                            ..selection =
                                                TextSelection.collapsed(
                                                  offset: item.mauSac.length,
                                                ),
                                        decoration: const InputDecoration(
                                          labelText: 'Màu',
                                        ),
                                        onChanged: (value) =>
                                            setDialogState(() {
                                              variants[index] = BienThe(
                                                id: item.id,
                                                mauSac: value,
                                                kichCo: item.kichCo,
                                                gia: item.gia,
                                                tonKho: item.tonKho,
                                              );
                                            }),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: TextEditingController(
                                              text: item.kichCo,
                                            )
                                            ..selection =
                                                TextSelection.collapsed(
                                                  offset: item.kichCo.length,
                                                ),
                                        decoration: const InputDecoration(
                                          labelText: 'Size',
                                        ),
                                        onChanged: (value) =>
                                            setDialogState(() {
                                              variants[index] = BienThe(
                                                id: item.id,
                                                mauSac: item.mauSac,
                                                kichCo: value,
                                                gia: item.gia,
                                                tonKho: item.tonKho,
                                              );
                                            }),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: TextEditingController(
                                              text: item.gia.toString(),
                                            )
                                            ..selection =
                                                TextSelection.collapsed(
                                                  offset:
                                                      item.gia.toString().length,
                                                ),
                                        decoration: const InputDecoration(
                                          labelText: 'Giá',
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) =>
                                            setDialogState(() {
                                              variants[index] = BienThe(
                                                id: item.id,
                                                mauSac: item.mauSac,
                                                kichCo: item.kichCo,
                                                gia: int.tryParse(value) ?? 0,
                                                tonKho: item.tonKho,
                                              );
                                            }),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: TextEditingController(
                                              text: item.tonKho.toString(),
                                            )
                                            ..selection =
                                                TextSelection.collapsed(
                                                  offset: item.tonKho
                                                      .toString()
                                                      .length,
                                                ),
                                        decoration: const InputDecoration(
                                          labelText: 'Số lượng',
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) => setDialogState(
                                          () {
                                            variants[index] = BienThe(
                                              id: item.id,
                                              mauSac: item.mauSac,
                                              kichCo: item.kichCo,
                                              gia: item.gia,
                                              tonKho:
                                                  int.tryParse(value) ?? 0,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => setDialogState(
                                      () => variants.removeAt(index),
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    label: const Text(
                                      'Xóa biến thể',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: dangLuu ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: dangLuu
                      ? null
                      : () async {
                          if (tenCtrl.text.trim().isEmpty) return;
                          setDialogState(() => dangLuu = true);
                          try {
                            final duongDanAnh = await _taiAnhLen(anhChon);
                            if (sanPham == null) {
                              await ref
                                  .read(sanPhamProvider.notifier)
                                  .taoSanPham(
                                    ten: tenCtrl.text.trim(),
                                    ma: maCtrl.text.trim().isEmpty
                                        ? tenCtrl.text.trim()
                                        : maCtrl.text.trim(),
                                    duongDanAnh: duongDanAnh,
                                    bienThes: variants,
                                  );
                            } else {
                              await ref
                                  .read(sanPhamProvider.notifier)
                                  .capNhatSanPham(
                                    id: sanPham.id,
                                    ten: tenCtrl.text.trim(),
                                    ma: maCtrl.text.trim().isEmpty
                                        ? tenCtrl.text.trim()
                                        : maCtrl.text.trim(),
                                    duongDanAnh: duongDanAnh.isNotEmpty
                                        ? duongDanAnh
                                        : sanPham.anhKey,
                                    bienThes: variants,
                                  );
                            }
                            if (!mounted) return;
                            if (context.mounted) Navigator.of(ctx).pop();
                          } catch (e) {
                            setDialogState(() => dangLuu = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi: $e')),
                              );
                            }
                          }
                        },
                  child: dangLuu
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sanPhamAsync = ref.watch(sanPhamProvider);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200 ? 3 : (width > 800 ? 2 : 1);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Sản Phẩm',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm Sản Phẩm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.activeGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _showDialogSanPham(context),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => ref.read(sanPhamProvider.notifier).lamMoi(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timKiemCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm…',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) =>
                  ref.read(sanPhamProvider.notifier).timKiem(value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: sanPhamAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 8),
                      Text(error.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(sanPhamProvider.notifier).lamMoi(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(child: Text('Chưa có sản phẩm nào'));
                  }
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 230,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, index) => _TheSanPhamNgang(
                      sanPham: products[index],
                      onEdit: () =>
                          _showDialogSanPham(context, sanPham: products[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ô ảnh preview có thể nhấn — hiện ảnh file, URL, hoặc placeholder
class _OAnhChonAnh extends StatelessWidget {
  final File? anhFile;
  final String? urlAnh;

  const _OAnhChonAnh({this.anhFile, this.urlAnh});

  @override
  Widget build(BuildContext context) {
    final coAnh = anhFile != null || (urlAnh != null && urlAnh!.isNotEmpty);

    Widget noiDungAnh;
    if (anhFile != null) {
      noiDungAnh = Image.file(
        anhFile!,
        width: 140,
        height: 140,
        fit: BoxFit.cover,
      );
    } else if (urlAnh != null && urlAnh!.isNotEmpty) {
      noiDungAnh = Image.network(
        urlAnh!,
        width: 140,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _OAnhTrong(),
      );
    } else {
      noiDungAnh = const _OAnhTrong();
    }

    return Stack(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textSecondary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.5),
            child: noiDungAnh,
          ),
        ),
        // Badge camera góc dưới phải khi đã có ảnh
        if (coAnh)
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.navSelected,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }
}

class _OAnhTrong extends StatelessWidget {
  const _OAnhTrong();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      color: AppColors.navUnselected,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 36,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 6),
          Text(
            'Nhấn để chọn ảnh',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TheSanPhamNgang extends ConsumerWidget {
  final SanPham sanPham;
  final VoidCallback onEdit;

  const _TheSanPhamNgang({required this.sanPham, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: sanPham.anh.isNotEmpty
                            ? Image.network(
                                sanPham.anh,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 56,
                                      height: 56,
                                      color: AppColors.navUnselected,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                        size: 20,
                                      ),
                                    ),
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.navUnselected,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 22,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sanPham.ten,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (sanPham.ma.isNotEmpty)
                              Text(
                                'Mã: ${sanPham.ma}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Xóa sản phẩm',
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xác nhận xóa?'),
                      content: Text(
                        'Bạn có chắc muốn xóa hẳn "${sanPham.ten}" khỏi hệ thống không?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Hủy'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            if (!context.mounted) return;
                            try {
                              await ref
                                  .read(sanPhamProvider.notifier)
                                  .xoaSanPham(sanPham.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã xóa sản phẩm thành công'),
                                  ),
                                );
                              }
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Xóa thất bại: $error'),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text(
                            'Xóa Khỏi DB',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: sanPham.bienThes
                    .map(
                      (variant) => Chip(
                        label: Text(
                          '${variant.tenHienThi} • ${variant.tonKho} cái • ${dinhDangTien(variant.gia)}',
                        ),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.navUnselected,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng tồn kho:',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                '${sanPham.tongTonKho}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: sanPham.tongTonKho > 0
                      ? AppColors.activeGreen
                      : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
