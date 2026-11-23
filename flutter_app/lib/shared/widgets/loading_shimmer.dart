import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingShimmer extends StatelessWidget {
  final int itemCount;

  const LoadingShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          height: 88,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(14),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1100.ms, color: highlightColor);
      },
    );
  }
}
