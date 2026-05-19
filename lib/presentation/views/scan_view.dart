import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../state/scanner_notifier.dart';
import '../widgets/glass_card.dart';
import '../widgets/radar_animation.dart';
import 'results_view.dart';

/// The active scanning screen that displays the RadarAnimation
/// and maps real-time progress updates from the background Isolate.
class ScanView extends StatelessWidget {
  const ScanView({super.key});

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
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.obsidianGradient,
            ),
          ),

          // Cyberpunk glowing ambient background spheres
          Positioned(
            top: 100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.electricBlue.withOpacity(0.06),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Consumer<ScannerNotifier>(
                  builder: (context, notifier, child) {
                    final progress = notifier.scanProgress;
                    final bool isFinished = !notifier.isScanning && progress != null && progress.isCompleted;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Back or Exit scan button
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                if (notifier.isScanning) {
                                  notifier.cancelScan();
                                }
                                Navigator.of(context).pop();
                              },
                            ),
                            Text(
                              isFinished ? 'Analyse Terminée' : 'Analyse en cours',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        
                        const Spacer(),

                        // Premium Radar Animation
                        Center(
                          child: RadarAnimation(
                            size: 240,
                            isScanning: notifier.isScanning,
                            centerWidget: Icon(
                              isFinished ? Icons.check_circle_outline_rounded : Icons.search,
                              color: isFinished ? AppColors.success : AppColors.obsidian,
                              size: 20,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Dynamic Real-time statistics card
                        GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: _buildStatColumn(
                                      context,
                                      label: 'Parcourus',
                                      value: '${progress?.filesScanned ?? 0}',
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatColumn(
                                      context,
                                      label: 'Doublons',
                                      value: '${progress?.duplicatesFound ?? 0}',
                                      valueColor: AppColors.hotPink,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatColumn(
                                      context,
                                      label: 'Espace gaspillé',
                                      value: _formatSize((progress?.totalDuplicateSize ?? 0).toDouble()),
                                      valueColor: AppColors.neonPurple,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: AppSpacing.lg),
                              const Divider(),
                              const SizedBox(height: AppSpacing.sm),

                              // Progress Bar Indicator
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                                child: LinearProgressIndicator(
                                  value: progress?.percentage ?? 0.0,
                                  backgroundColor: Colors.white.withOpacity(0.04),
                                  color: isFinished ? AppColors.success : AppColors.electricBlue,
                                  minHeight: 6.0,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Current File Text
                              Text(
                                isFinished ? 'Analyse complétée avec succès.' : 'Fichier actuel :',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                notifier.statusMessage,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontFamily: 'monospace',
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Action Buttons
                        Row(
                          children: [
                            if (!isFinished)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    notifier.cancelScan();
                                    Navigator.of(context).pop();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(color: AppColors.error),
                                  ),
                                  child: const Text('ANNULER'),
                                ),
                              ),
                            if (isFinished) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('RETOUR'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    boxShadow: (progress?.duplicatesFound ?? 0) > 0 ? AppShadows.neonGlow : null,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: (progress?.duplicatesFound ?? 0) > 0
                                        ? () {
                                            Navigator.of(context).pushReplacement(
                                              MaterialPageRoute(
                                                builder: (_) => const ResultsView(),
                                              ),
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.electricBlue,
                                      foregroundColor: AppColors.obsidian,
                                    ),
                                    child: const Text('VOIR LES DOUBLONS'),
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
          ),
        ),
        const SizedBox(height: 4.0),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}
