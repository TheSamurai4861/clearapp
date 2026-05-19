import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/file_item.dart';
import '../state/scanner_notifier.dart';
import '../widgets/glass_card.dart';

/// The results screen showing identified duplicates grouped, allowing smart auto-select,
/// manual tweaking, and triggering the secure deletion cleanup process.
class ResultsView extends StatefulWidget {
  const ResultsView({super.key});

  @override
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView> {
  @override
  void initState() {
    super.initState();
    // Default smart selection on load: keep oldest files, delete newer duplicates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScannerNotifier>().autoSelectDuplicates(keepOldest: true);
    });
  }

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

  IconData _getFileIcon(String ext) {
    switch (ext) {
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
      case 'gif':
        return Icons.image_outlined;
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
        return Icons.video_library_outlined;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'm4a':
        return Icons.audio_file_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'zip':
      case 'rar':
      case 'tar':
      case 'gz':
      case '7z':
        return Icons.folder_zip_outlined;
      case 'exe':
      case 'msi':
        return Icons.settings_applications_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileIconColor(String ext) {
    switch (ext) {
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
        return AppColors.success;
      case 'mp4':
      case 'mkv':
      case 'mov':
        return AppColors.info;
      case 'pdf':
        return AppColors.hotPink;
      case 'zip':
      case 'rar':
      case '7z':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScannerNotifier>(
      builder: (context, notifier, child) {
        // If actively deleting, display the satisfying cleanup progress screen
        if (notifier.isDeleting) {
          return _buildDeletingView(context, notifier);
        }

        // If deletion completed, show the beautiful Success screen
        if (notifier.deletionResult != null && notifier.deletionResult!.isCompleted) {
          return _buildSuccessView(context, notifier);
        }

        final groups = notifier.duplicates;
        final selectedSize = notifier.selectedDeletionSize;
        final totalWasted = groups.fold(0, (sum, g) => sum + g.wastedSize);

        return Scaffold(
          body: Stack(
            children: [
              // Background
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.obsidianGradient,
                ),
              ),

              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header navigation bar
                    _buildHeader(context, notifier, selectedSize, totalWasted),

                    // Smart Filter actions
                    _buildSmartFilters(context, notifier),

                    // Main duplicates groups list
                    Expanded(
                      child: groups.isEmpty
                          ? _buildEmptyState(context)
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              itemCount: groups.length,
                              itemBuilder: (context, index) {
                                final group = groups[index];
                                return _buildDuplicateGroupCard(context, notifier, group);
                              },
                            ),
                    ),

                    // Bottom Cleanup bar
                    _buildBottomCleanupBar(context, notifier, selectedSize),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ScannerNotifier notifier,
    int selectedSize,
    int totalWasted,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fichiers en double',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_formatSize(selectedSize.toDouble())} sélectionnés sur ${_formatSize(totalWasted.toDouble())} gaspillés',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartFilters(BuildContext context, ScannerNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.deepSpace,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: Colors.white.withOpacity(0.03),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          Text(
            'Sélection Auto :',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
          ),
          Wrap(
            spacing: 8.0,
            children: [
              TextButton(
                onPressed: () => notifier.autoSelectDuplicates(keepOldest: true),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Garder le plus ancien',
                  style: TextStyle(fontSize: 12.0, color: AppColors.electricBlue),
                ),
              ),
              TextButton(
                onPressed: () => notifier.autoSelectDuplicates(keepOldest: false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Garder le plus récent',
                  style: TextStyle(fontSize: 12.0, color: AppColors.neonPurple),
                ),
              ),
              TextButton(
                onPressed: () => notifier.clearAllSelection(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Tout désélectionner',
                  style: TextStyle(fontSize: 12.0, color: Colors.white70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCompareDialog(BuildContext context, DuplicateGroup group) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<ScannerNotifier>(
          builder: (context, notifier, child) {
            // Find fresh group instance to get updated selected states
            final activeGroup = notifier.duplicates.firstWhere(
              (g) => g.hash == group.hash,
              orElse: () => group,
            );

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(AppSpacing.md),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dismissible backdrop
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      color: Colors.black.withOpacity(0.9),
                    ),
                  ),

                  // Comparison container
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 900),
                    margin: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.deepSpace,
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.electricBlue.withOpacity(0.15),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          _buildCompareHeader(context, activeGroup),

                          // Image contents
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isMobile = constraints.maxWidth < 650;
                                  if (isMobile) {
                                    // Stacked layout for compact screen
                                    return Column(
                                      children: activeGroup.files.map((file) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                                          child: _buildComparisonCard(context, notifier, file, true),
                                        );
                                      }).toList(),
                                    );
                                  } else {
                                    // Side-by-side layout for desktop
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: activeGroup.files.map((file) {
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                            child: _buildComparisonCard(context, notifier, file, false),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),

                          // Bottom Footer information / close
                          _buildCompareFooter(context, activeGroup),
                        ],
                      ),
                    ),
                  ),

                  // Top right close button
                  Positioned(
                    top: 15,
                    right: 15,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompareHeader(BuildContext context, DuplicateGroup group) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.compare_rounded,
            color: AppColors.electricBlue,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comparaison Visuelle',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Taille : ${_formatSize(group.fileSize.toDouble())} • ${group.files.length} fichiers trouvés',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
    BuildContext context,
    ScannerNotifier notifier,
    FileItem file,
    bool isStacked,
  ) {
    final double imageHeight = isStacked ? 200.0 : 280.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: file.isSelected
              ? AppColors.hotPink.withOpacity(0.6)
              : AppColors.electricBlue.withOpacity(0.4),
          width: file.isSelected ? 2.0 : 1.5,
        ),
        boxShadow: file.isSelected
            ? [
                BoxShadow(
                  color: AppColors.hotPink.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.md - 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Visual Preview Section
            Stack(
              children: [
                Container(
                  height: imageHeight,
                  width: double.infinity,
                  color: Colors.black26,
                  child: Image.file(
                    File(file.path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.deepSpace,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textSecondary,
                            size: 40,
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'Aperçu indisponible',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Status Ribbon
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: file.isSelected
                          ? AppColors.hotPink.withOpacity(0.9)
                          : AppColors.success.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          file.isSelected ? Icons.delete_outline_rounded : Icons.check_circle_outline,
                          color: AppColors.obsidian,
                          size: 14,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          file.isSelected ? 'À SUPPRIMER' : 'CONSERVÉ',
                          style: const TextStyle(
                            color: AppColors.obsidian,
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Metadata & Select Button Section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Path Text
                  Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Text(
                      file.path,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10.0,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Modification Date
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: AppColors.textSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Modifié le : ${file.modifiedDate.day}/${file.modifiedDate.month}/${file.modifiedDate.year} ${file.modifiedDate.hour.toString().padLeft(2, '0')}:${file.modifiedDate.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.0,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Action Button
                  ElevatedButton(
                    onPressed: () => notifier.toggleFileSelection(file),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: file.isSelected
                          ? Colors.white.withOpacity(0.08)
                          : AppColors.electricBlue,
                      foregroundColor: file.isSelected
                          ? AppColors.textPrimary
                          : AppColors.obsidian,
                      elevation: file.isSelected ? 0 : 4,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    ),
                    child: Text(
                      file.isSelected ? 'CONSERVER LE FICHIER' : 'SUPPRIMER CE FICHIER',
                      style: const TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
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

  Widget _buildCompareFooter(BuildContext context, DuplicateGroup group) {
    final int toDeleteCount = group.files.where((f) => f.isSelected).length;
    final int toKeepCount = group.files.length - toDeleteCount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Summary text
          Expanded(
            child: Text(
              toKeepCount == 0
                  ? '⚠️ Attention : vous supprimez tous les fichiers !'
                  : 'À conserver : $toKeepCount | À supprimer : $toDeleteCount',
              style: TextStyle(
                color: toKeepCount == 0 ? AppColors.warning : AppColors.textSecondary,
                fontSize: 12.0,
                fontWeight: toKeepCount == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // OK button
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.electricBlue,
              side: const BorderSide(color: AppColors.electricBlue),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicateGroupCard(
    BuildContext context,
    ScannerNotifier notifier,
    DuplicateGroup group,
  ) {
    final firstFile = group.files.first;
    final ext = firstFile.fileExtension;
    final bool isImage = ['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext.toLowerCase());

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Group Title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: _getFileIconColor(ext).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: Icon(
                    _getFileIcon(ext),
                    color: _getFileIconColor(ext),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstFile.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Taille : ${_formatSize(group.fileSize.toDouble())} • ${group.files.length} doublons',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (isImage)
                  TextButton.icon(
                    onPressed: () => _showCompareDialog(context, group),
                    icon: const Icon(
                      Icons.compare_rounded,
                      size: 16,
                      color: AppColors.electricBlue,
                    ),
                    label: const Text(
                      'Comparer',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: AppColors.electricBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4.0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1.0),
            const SizedBox(height: AppSpacing.sm),

            // Duplicate File occurrences list inside the group
            ...group.files.map((file) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    // Gradient Glowing Checkbox
                    GestureDetector(
                      onTap: () => notifier.toggleFileSelection(file),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: file.isSelected
                                ? AppColors.electricBlue
                                : AppColors.textSecondary.withOpacity(0.4),
                            width: 1.5,
                          ),
                          gradient: file.isSelected ? AppColors.premiumGradient : null,
                          boxShadow: file.isSelected ? AppShadows.neonGlow : null,
                        ),
                        child: file.isSelected
                          ? const Icon(
                              Icons.check,
                              size: 12,
                              color: AppColors.obsidian,
                            )
                          : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Image Thumbnail (if physical image exists)
                    if (isImage) ...[
                      GestureDetector(
                        onTap: () => _showCompareDialog(context, group),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                                width: 1.0,
                              ),
                            ),
                            child: Hero(
                              tag: 'hero-${file.path}',
                              child: Image.file(
                                File(file.path),
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: AppColors.deepSpace,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: AppColors.textSecondary,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.path,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  fontSize: 10.5,
                                  color: file.isSelected ? AppColors.hotPink : AppColors.textPrimary,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'Modifié le : ${file.modifiedDate.day}/${file.modifiedDate.month}/${file.modifiedDate.year} ${file.modifiedDate.hour}:${file.modifiedDate.minute}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 9.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCleanupBar(
    BuildContext context,
    ScannerNotifier notifier,
    int selectedSize,
  ) {
    final hasSelection = selectedSize > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.deepSpace,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.03),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          boxShadow: hasSelection ? AppShadows.neonGlow : null,
        ),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.delete_sweep_outlined),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              hasSelection
                  ? 'NETTOYER LES DOUBLONS (${_formatSize(selectedSize.toDouble())})'
                  : 'AUCUN DOUBLON SÉLECTIONNÉ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          onPressed: hasSelection
              ? () {
                  _showConfirmDeletionDialog(context, notifier);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricBlue,
            foregroundColor: AppColors.obsidian,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            disabledBackgroundColor: Colors.white.withOpacity(0.04),
            disabledForegroundColor: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  void _showConfirmDeletionDialog(BuildContext context, ScannerNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.deepSpace,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          title: const Text('Confirmer la suppression'),
          content: Text(
            'Voulez-vous vraiment supprimer définitivement ${notifier.selectedFilesToDelete.length} fichiers ? '
            'Cette action libérera ${_formatSize(notifier.selectedDeletionSize.toDouble())} de stockage.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ANNULER', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                notifier.executeDeletion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                foregroundColor: AppColors.obsidian,
              ),
              child: const Text('SUPPRIMER'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.done_all_rounded,
          color: AppColors.success,
          size: 64,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Aucun doublon !',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Votre espace de stockage est impeccable.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDeletingView(BuildContext context, ScannerNotifier notifier) {
    final result = notifier.deletionResult;
    final int deleted = result?.filesDeleted ?? 0;
    final int total = result?.totalFilesToDelete ?? 1;
    final double percentage = deleted / total;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.obsidianGradient,
            ),
          ),
          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          color: AppColors.electricBlue,
                          strokeWidth: 5.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Nettoyage en cours',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'ClearApp supprime les doublons sélectionnés en toute sécurité...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Progress percent
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 8.0,
                        backgroundColor: Colors.white.withOpacity(0.04),
                        color: AppColors.electricBlue,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Fichiers nettoyés : $deleted / $total',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, ScannerNotifier notifier) {
    final result = notifier.deletionResult!;
    
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.obsidianGradient,
            ),
          ),
          
          // Confetti-like ambient cyan/purple nodes
          Positioned(
            top: 150,
            left: 50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withOpacity(0.08),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Big green glowing check icon
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.success.withOpacity(0.1),
                              border: Border.all(
                                color: AppColors.success,
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withOpacity(0.2),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: AppColors.success,
                              size: 48,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        
                        Text(
                          'Nettoyage Réussi !',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        Text(
                          'Félicitations, vous avez libéré un espace précieux sur votre appareil.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        const Divider(),
                        const SizedBox(height: AppSpacing.md),

                        _buildSummaryRow(
                          context,
                          label: 'Espace disque récupéré',
                          value: _formatSize(result.spaceReclaimed.toDouble()),
                          valueColor: AppColors.success,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSummaryRow(
                          context,
                          label: 'Fichiers supprimés',
                          value: '${result.filesDeleted} fichiers',
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // Return home button
                        ElevatedButton(
                          onPressed: () {
                            // Clear the deletion state to allow scanning again
                            notifier.selectDirectory(notifier.selectedDirectory ?? '');
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.electricBlue,
                            foregroundColor: AppColors.obsidian,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          ),
                          child: const Text('RETOUR À L\'ACCUEIL'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}
