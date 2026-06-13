import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import 'products_provider.dart';

// ── Products Page ─────────────────────────────────────────────────────────────
//
// Shows the product catalog. ConsumerWidget = a Flutter widget that can
// read Riverpod providers via the `ref` parameter.
//
// Rule: Pages only read providers and call provider methods.
//       They never call the repository directly.

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch rebuilds this widget whenever the products list changes.
    final productsAsync = ref.watch(productsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
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
                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                  onPressed: () => ref.read(productsProvider.notifier).refresh(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Search bar ─────────────────────────────────────
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm…',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (q) => ref.read(productsProvider.notifier).search(q),
            ),

            const SizedBox(height: 16),

            // ── Content area — handles loading / error / data ──
            Expanded(
              child: productsAsync.when(
                // While loading: show a spinner
                loading: () => const Center(child: CircularProgressIndicator()),

                // On error: show message with retry button
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(productsProvider.notifier).refresh(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),

                // On success: show product list
                data: (products) => products.isEmpty
                    ? const Center(
                        child: Text('Chưa có sản phẩm nào', style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : ListView.separated(
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _ProductCard(product: products[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'vi_VN');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.navUnselected,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (product.code.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Mã: ${product.code}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 4),
                // Variants
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: product.variants.map((v) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.navUnselected,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${v.displayName}: ${fmt.format(v.price)}₫ (${v.stock})',
                        style: const TextStyle(fontSize: 10, color: AppColors.textPrimary),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Total stock badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: product.totalStock > 0 ? AppColors.activeGreen.withOpacity(0.1) : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${product.totalStock}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: product.totalStock > 0 ? AppColors.activeGreen : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
