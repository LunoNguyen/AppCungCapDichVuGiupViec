import 'package:flutter/material.dart';
import '../core/app_colors.dart';

// ─── Service Card ──────────────────────────────────────────────────────────
class ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final IconData icon;
  final Color iconBg;
  final VoidCallback? onTap;

  const ServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.icon,
    this.iconBg = AppColors.brand500,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [iconBg.withOpacity(0.85), iconBg],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(icon, color: AppColors.white, size: 40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brand300.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      price,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.brand600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Star Rating ───────────────────────────────────────────────────────────
class StarRating extends StatelessWidget {
  final double rating;
  final double size;

  const StarRating({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star, color: AppColors.star, size: size);
        } else if (i < rating) {
          return Icon(Icons.star_half, color: AppColors.star, size: size);
        }
        return Icon(Icons.star_border, color: AppColors.star, size: size);
      }),
    );
  }
}

// ─── Status Chip ───────────────────────────────────────────────────────────
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.bg,
  });

  factory StatusChip.pending() => const StatusChip(
        label: 'Chờ xác nhận',
        color: Color(0xFFFB8C00),
        bg: Color(0xFFFFF3E0),
      );

  factory StatusChip.confirmed() => const StatusChip(
        label: 'Đã xác nhận',
        color: AppColors.brand600,
        bg: Color(0xFFE0F4F7),
      );

  factory StatusChip.inProgress() => const StatusChip(
        label: 'Đang thực hiện',
        color: Color(0xFF1565C0),
        bg: Color(0xFFE3F2FD),
      );

  factory StatusChip.completed() => const StatusChip(
        label: 'Hoàn thành',
        color: Color(0xFF2E7D32),
        bg: Color(0xFFE8F5E9),
      );

  factory StatusChip.cancelled() => const StatusChip(
        label: 'Đã hủy',
        color: Color(0xFFC62828),
        bg: Color(0xFFFFEBEE),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.brand500,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Notification Item ─────────────────────────────────────────────────────
class NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final bool isRead;

  const NotificationItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead ? AppColors.white : AppColors.brand300.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead ? AppColors.divider : AppColors.brand300.withOpacity(0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight:
                              isRead ? FontWeight.w500 : FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (!isRead)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.brand500,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Booking List Item ─────────────────────────────────────────────────────
class BookingListItem extends StatelessWidget {
  final String serviceName;
  final String collaboratorName;
  final String dateTime;
  final String address;
  final String price;
  final Widget statusChip;
  final VoidCallback? onTap;

  const BookingListItem({
    super.key,
    required this.serviceName,
    required this.collaboratorName,
    required this.dateTime,
    required this.address,
    required this.price,
    required this.statusChip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brand300.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.home_repair_service,
                    color: AppColors.brand500,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'CTV: $collaboratorName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                statusChip,
              ],
            ),
            const Divider(height: 16, color: AppColors.divider),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(dateTime,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                Text(
                  price,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.brand600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
