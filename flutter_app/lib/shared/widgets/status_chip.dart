import 'package:flutter/material.dart';
import '../../core/models/invoice.dart';
import '../../core/models/order.dart';
import '../../core/models/truck.dart';
import '../../core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const StatusChip({
    super.key,
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  factory StatusChip.order(OrderStatus status) {
    return switch (status) {
      OrderStatus.requested => const StatusChip(
          label: 'Requested',
          textColor: Color(0xFF7C3AED),
          backgroundColor: Color(0xFFEDE9FE),
        ),
      OrderStatus.pending => const StatusChip(
          label: 'Pending',
          textColor: AppColors.warning,
          backgroundColor: AppColors.warningBg,
        ),
      OrderStatus.confirmed => const StatusChip(
          label: 'Confirmed',
          textColor: AppColors.info,
          backgroundColor: AppColors.infoBg,
        ),
      OrderStatus.inTransit => const StatusChip(
          label: 'In Transit',
          textColor: Color(0xFF0284C7),
          backgroundColor: Color(0xFFE0F2FE),
        ),
      OrderStatus.delivered => const StatusChip(
          label: 'Delivered',
          textColor: Color(0xFF0D9488),
          backgroundColor: Color(0xFFCCFBF1),
        ),
      OrderStatus.invoiced => const StatusChip(
          label: 'Invoiced',
          textColor: Color(0xFF4338CA),
          backgroundColor: Color(0xFFE0E7FF),
        ),
      OrderStatus.paid => const StatusChip(
          label: 'Paid',
          textColor: AppColors.profit,
          backgroundColor: AppColors.profitBg,
        ),
      OrderStatus.cancelled => const StatusChip(
          label: 'Cancelled',
          textColor: AppColors.loss,
          backgroundColor: AppColors.lossBg,
        ),
    };
  }

  factory StatusChip.payment(PaymentStatus status) {
    return switch (status) {
      PaymentStatus.paid => const StatusChip(
          label: 'Paid',
          textColor: AppColors.profit,
          backgroundColor: AppColors.profitBg,
        ),
      PaymentStatus.partiallyPaid => const StatusChip(
          label: 'Partially Paid',
          textColor: AppColors.warning,
          backgroundColor: AppColors.warningBg,
        ),
      PaymentStatus.unpaid => const StatusChip(
          label: 'Unpaid',
          textColor: AppColors.loss,
          backgroundColor: AppColors.lossBg,
        ),
    };
  }

  factory StatusChip.truck(TruckStatus status) {
    return switch (status) {
      TruckStatus.active => const StatusChip(
          label: 'Active',
          textColor: AppColors.profit,
          backgroundColor: AppColors.profitBg,
        ),
      TruckStatus.maintenance => const StatusChip(
          label: 'In Maintenance',
          textColor: AppColors.warning,
          backgroundColor: AppColors.warningBg,
        ),
      TruckStatus.inactive => const StatusChip(
          label: 'Inactive',
          textColor: Color(0xFF64748B),
          backgroundColor: Color(0xFFF1F5F9),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
