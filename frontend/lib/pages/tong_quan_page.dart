import 'package:flutter/material.dart';
import '../core/theme.dart';

// ── Dummy data models ────────────────────────────────────────────────────────

class _StatData {
  final String title;
  final String value;
  final String sub;
  final IconData icon;

  const _StatData({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
  });
}

class _ActivityData {
  final String text;
  final String time;

  const _ActivityData({required this.text, required this.time});
}

// ── Page ─────────────────────────────────────────────────────────────────────

class TongQuanPage extends StatelessWidget {
  const TongQuanPage({super.key});

  static const _stats = [
    _StatData(
      title: 'Tổng Đơn Hàng',
      value: '248',
      sub: '+12% tuần này',
      icon: Icons.shopping_cart_outlined,
    ),
    _StatData(
      title: 'Doanh Thu',
      value: '45.6M ₫',
      sub: '+8% tuần này',
      icon: Icons.monetization_on_outlined,
    ),
    _StatData(
      title: 'Khách Hàng',
      value: '89',
      sub: '+5 người mới',
      icon: Icons.people_outline,
    ),
    _StatData(
      title: 'Thiết Bị Online',
      value: '12',
      sub: 'Đang hoạt động',
      icon: Icons.devices_outlined,
    ),
  ];

  static const _activities = [
    _ActivityData(text: 'Đơn hàng #1042 đã được xác nhận', time: '10:30 SA'),
    _ActivityData(text: 'Khách hàng mới: Nguyễn Văn A', time: '09:15 SA'),
    _ActivityData(text: 'Sản phẩm "Bàn làm việc" đã cập nhật', time: '08:50 SA'),
    _ActivityData(text: 'Đơn hàng #1041 đã giao thành công', time: '08:20 SA'),
    _ActivityData(text: 'Báo cáo tháng 5 đã được tạo', time: 'Hôm qua'),
  ];

  @override
  Widget build(BuildContext context) {
    // No SingleChildScrollView — Column + Expanded fills the screen exactly.
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ────────────────────────────────────────
            const Text(
              'Tổng Quan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 10),

            // ── Status banner (flat, blends into background) ──
            _buildStatusBanner(),

            const SizedBox(height: 10),

            // ── 2×2 stats grid — Expanded takes ~55% of remaining space ──
            Expanded(
              flex: 55,
              child: _buildStatsGrid(),
            ),

            const SizedBox(height: 10),

            // ── Activity section — Expanded takes ~45% of remaining space ──
            Expanded(
              flex: 45,
              child: _buildActivitySection(),
            ),
          ],
        ),
      ),
    );
  }

  // Flat banner — same color as background so it blends in (like the reference image)
  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.circle, color: AppColors.activeGreen, size: 9),
          SizedBox(width: 8),
          Text(
            'Hoạt Động',
            style: TextStyle(
              color: AppColors.activeGreen,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Spacer(),
          Text(
            'Hệ thống đang hoạt động bình thường',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // 2×2 grid built with Row + Expanded so cards fill the available height.
  Widget _buildStatsGrid() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildStatCard(_stats[0])),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard(_stats[1])),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildStatCard(_stats[2])),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard(_stats[3])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(_StatData stat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(stat.icon, color: AppColors.textSecondary, size: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                stat.title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stat.sub,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.activeGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Activity section fills its Expanded slot; the ListView scrolls inside
  // the bounded card if there are many items.
  Widget _buildActivitySection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch Sử Hoạt Động',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _activities.map(_buildActivityItem).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(_ActivityData activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.navSelected,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              activity.text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            activity.time,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
