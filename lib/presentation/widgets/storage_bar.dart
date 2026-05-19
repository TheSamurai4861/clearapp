import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A premium animated storage gauge that visually highlights:
/// - Space taken by other files (Deep Slate)
/// - Space taken by duplicate files (Neon Purple/Hot Pink gradient)
/// - Free space (Obsidian/subtle outline)
class StorageBar extends StatelessWidget {
  final double totalBytes;
  final double usedBytes;
  final double duplicateBytes;
  final String label;

  const StorageBar({
    super.key,
    required this.totalBytes,
    required this.usedBytes,
    required this.duplicateBytes,
    this.label = 'Stockage Appareil',
  });

  String _formatSize(double bytes) {
    if (bytes <= 0) return '0 Mo';
    const suffixes = ['octets', 'Ko', 'Mo', 'Go', 'To'];
    int i = 0;
    double size = bytes;
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final double freeBytes = totalBytes - usedBytes;
    final double standardUsedBytes = usedBytes - duplicateBytes;

    // Calculate percentage ratios
    final double totalRatio = totalBytes > 0 ? 1.0 : 0.0;
    final double otherUsedRatio = totalBytes > 0 ? (standardUsedBytes.clamp(0.0, totalBytes) / totalBytes) : 0.0;
    final double duplicateRatio = totalBytes > 0 ? (duplicateBytes.clamp(0.0, totalBytes) / totalBytes) : 0.0;
    final double freeRatio = (1.0 - otherUsedRatio - duplicateRatio).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${_formatSize(usedBytes)} / ${_formatSize(totalBytes)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        
        // Multi-segment progress bar with animations
        ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          child: Container(
            height: 16.0,
            width: double.infinity,
            color: AppColors.deepSpace,
            child: Row(
              children: [
                // 1. Other Used Files
                if (otherUsedRatio > 0)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: otherUsedRatio),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Expanded(
                        flex: (value * 1000).toInt(),
                        child: Container(
                          color: AppColors.textMuted.withOpacity(0.5),
                        ),
                      );
                    },
                  ),
                
                // 2. Duplicate Files (glowing pink/purple segment)
                if (duplicateRatio > 0)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: duplicateRatio),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Expanded(
                        flex: (value * 1000).toInt(),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.neonPurple, AppColors.hotPink],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                
                // 3. Free Space
                if (freeRatio > 0)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: freeRatio),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Expanded(
                        flex: (value * 1000).toInt(),
                        child: Container(
                          color: Colors.white.withOpacity(0.04),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Legend indicators
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.spaceBetween,
          children: [
            _buildLegendItem(
              context,
              color: AppColors.textMuted.withOpacity(0.5),
              label: 'Autres fichiers',
              value: _formatSize(standardUsedBytes),
            ),
            _buildLegendItem(
              context,
              gradient: const LinearGradient(
                colors: [AppColors.neonPurple, AppColors.hotPink],
              ),
              label: 'Doublons trouvés',
              value: _formatSize(duplicateBytes),
              highlight: duplicateBytes > 0,
            ),
            _buildLegendItem(
              context,
              color: Colors.white.withOpacity(0.1),
              label: 'Espace libre',
              value: _formatSize(freeBytes),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    Color? color,
    Gradient? gradient,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                gradient: gradient,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.0,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 2.0),
        Padding(
          padding: const EdgeInsets.only(left: 14.0),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: highlight ? AppColors.hotPink : AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}
