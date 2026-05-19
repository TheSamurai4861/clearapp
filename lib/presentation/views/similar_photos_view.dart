import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/file_item.dart';
import '../../domain/entities/similar_image_group.dart';
import '../state/scanner_notifier.dart';
import '../widgets/glass_card.dart';
import '../widgets/radar_animation.dart';

/// Interactive premium view to compare and clean similar photos.
/// Built with the Cyber-Obsidian theme (deep dark backgrounds with neon pink/purple/blue accents).
class SimilarPhotosView extends StatefulWidget {
  final bool scanLibrary;
  const SimilarPhotosView({super.key, this.scanLibrary = false});

  @override
  State<SimilarPhotosView> createState() => _SimilarPhotosViewState();
}

class _SimilarPhotosViewState extends State<SimilarPhotosView> {
  int _currentGroupIndex = 0;
  bool _hasDeleted = false;

  @override
  void initState() {
    super.initState();
    // Trigger similar photos scan automatically when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<ScannerNotifier>();
      if (widget.scanLibrary) {
        notifier.startSimilarPhotosScan(scanLibrary: true);
      } else {
        final path = notifier.selectedDirectory;
        if (path != null) {
          notifier.startSimilarPhotosScan(path: path);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 700;

    return Consumer<ScannerNotifier>(
      builder: (context, notifier, child) {
        Widget body;

        if (notifier.isScanningSimilar) {
          body = _buildScanningState(context, notifier);
        } else if (notifier.isDeleting) {
          body = _buildDeletingState(context, notifier);
        } else if (_hasDeleted || (notifier.deletionResult != null && notifier.deletionResult!.isCompleted)) {
          body = _buildSuccessState(context, notifier);
        } else if (notifier.similarGroups.isEmpty) {
          body = _buildEmptyState(context);
        } else {
          body = _buildComparisonState(context, notifier, isMobile);
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
              onPressed: () {
                if (notifier.isScanningSimilar) {
                  notifier.cancelSimilarPhotosScan();
                }
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              'Nettoyeur de Galerie',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.8,
                  ),
            ),
            centerTitle: true,
          ),
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // Deep obsidian backdrop
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.obsidianGradient,
                ),
              ),

              // Glowing magenta background sphere
              Positioned(
                top: 100,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.pinkAccent.withOpacity(0.06),
                  ),
                ),
              ),

              SafeArea(child: body),
            ],
          ),
        );
      },
    );
  }

  /// Displays the scanning state with a pulsing radar and neon violet glow.
  Widget _buildScanningState(BuildContext context, ScannerNotifier notifier) {
    final progress = notifier.similarPhotosProgress;
    final percentage = progress?.percentage ?? 0.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const RadarAnimation(),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'ANALYSE DE LA GALERIE EN COURS',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: Colors.pinkAccent,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 6,
                width: 250,
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  color: Colors.pinkAccent,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Groupes détectés : ${progress?.groupsFound ?? 0}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(
                notifier.statusMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            OutlinedButton.icon(
              icon: const Icon(Icons.stop_rounded),
              label: const Text('ANNULER'),
              onPressed: () => notifier.cancelSimilarPhotosScan(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.pinkAccent,
                side: const BorderSide(color: Colors.pinkAccent),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays the active deletion phase.
  Widget _buildDeletingState(BuildContext context, ScannerNotifier notifier) {
    final result = notifier.deletionResult;
    final deleted = result?.filesDeleted ?? 0;
    final total = result?.totalFilesToDelete ?? 0;
    final progress = total > 0 ? deleted / total : 0.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    color: Colors.pinkAccent,
                    backgroundColor: Colors.white.withOpacity(0.05),
                  ),
                ),
                Icon(
                  Icons.delete_sweep_rounded,
                  size: 54,
                  color: Colors.pinkAccent.withOpacity(0.9),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'SUPPRESSION DES IMAGES...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: Colors.pinkAccent,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$deleted / $total fichiers supprimés',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Libération d\'espace en cours...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays the final victory / celebration state.
  Widget _buildSuccessState(BuildContext context, ScannerNotifier notifier) {
    final reclaimed = notifier.deletionResult?.spaceReclaimed ?? 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withOpacity(0.1),
                  border: Border.all(color: AppColors.success, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'NETTOYAGE TERMINÉ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: AppColors.success,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Votre galerie respire mieux !',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Espace libéré',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _formatBytes(reclaimed.toDouble()),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.obsidian,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
                ),
                child: const Text('RETOUR À L\'ACCUEIL'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Displays when no duplicates/similar photos are found.
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.02),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                size: 36,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Galerie impeccable',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Aucune photo similaire ou doublon temporel n\'a été détecté dans ce répertoire.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                foregroundColor: AppColors.obsidian,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              ),
              child: const Text('RETOUR'),
            ),
          ],
        ),
      ),
    );
  }

  /// Comparative state showing two images side-by-side or stacked.
  Widget _buildComparisonState(BuildContext context, ScannerNotifier notifier, bool isMobile) {
    final groups = notifier.similarGroups;
    if (_currentGroupIndex >= groups.length) {
      _currentGroupIndex = 0;
    }
    final group = groups[_currentGroupIndex];
    
    // Safety check: similar image group must contain at least 2 images for visual choice
    if (group.images.length < 2) {
      return const SizedBox.shrink();
    }

    final FileItem imgA = group.images[0];
    final FileItem imgB = group.images[1];

    final isASelected = imgA.isSelected; // selected for deletion
    final isBSelected = imgB.isSelected; // selected for deletion

    final totalSavings = groups.fold(0, (sum, g) => sum + g.potentialSavings);

    return Column(
      children: [
        // Navigation Stepper (X / Y) with premium thin glowing bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rafale ${_currentGroupIndex + 1} sur ${groups.length}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent,
                        ),
                  ),
                  Text(
                    'Économie totale : ${_formatBytes(totalSavings.toDouble())}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Stack(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    width: MediaQuery.of(context).size.width *
                        ((_currentGroupIndex + 1) / groups.length),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.pinkAccent, AppColors.neonPurple],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Group similarity reason card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.pinkAccent, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    group.reason,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Interactive split comparison screens (Side-by-side or stacked)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: isMobile
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildImageCard(context, notifier, group, imgA, isASelected, true),
                        const SizedBox(height: AppSpacing.md),
                        _buildImageCard(context, notifier, group, imgB, isBSelected, false),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildImageCard(context, notifier, group, imgA, isASelected, true),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: _buildImageCard(context, notifier, group, imgB, isBSelected, false),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Stepper control and final action bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: _currentGroupIndex > 0
                    ? () {
                        setState(() {
                          _currentGroupIndex--;
                        });
                      }
                    : null,
                style: IconButton.styleFrom(
                  disabledForegroundColor: Colors.white10,
                  foregroundColor: Colors.white70,
                ),
              ),

              // Keep/Delete summary + main execute cleaning action
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cleaning_services_rounded, color: AppColors.obsidian),
                      label: const Text(
                        'SUPPRIMER LES PHOTOS REJETÉES',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                      ),
                      onPressed: () {
                        setState(() {
                          _hasDeleted = true;
                        });
                        notifier.executeDeletion();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: AppColors.obsidian,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Next
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                onPressed: _currentGroupIndex < groups.length - 1
                    ? () {
                        setState(() {
                          _currentGroupIndex++;
                        });
                      }
                    : null,
                style: IconButton.styleFrom(
                  disabledForegroundColor: Colors.white10,
                  foregroundColor: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds each individual image card in the split-screen, showing the image and metadata.
  Widget _buildImageCard(
    BuildContext context,
    ScannerNotifier notifier,
    SimilarImageGroup group,
    FileItem item,
    bool isSelectedForDeletion,
    bool isDefaultRecommendation,
  ) {
    final bool keep = !isSelectedForDeletion;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: keep ? Colors.greenAccent.withOpacity(0.4) : Colors.pinkAccent.withOpacity(0.2),
          width: keep ? 2.0 : 1.5,
        ),
        boxShadow: keep
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.06),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview Header (Mock Sunset/Selfie or physical File)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppBorderRadius.lg - 2),
                    ),
                    child: _renderImagePreview(item.path),
                  ),

                  // Shadow gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Recommended / Badge label overlay
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDefaultRecommendation
                            ? Colors.greenAccent.withOpacity(0.85)
                            : Colors.blueAccent.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isDefaultRecommendation ? 'RECOMMANDÉ' : 'PLUS RÉCENT',
                        style: const TextStyle(
                          color: AppColors.obsidian,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Actions / Status overlay Ribbon
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                      decoration: BoxDecoration(
                        color: keep ? Colors.greenAccent : Colors.pinkAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        keep ? 'CONSERVÉ' : 'À SUPPRIMER',
                        style: const TextStyle(
                          color: AppColors.obsidian,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Metadata & Select Buttons Footer
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatBytes(item.size.toDouble()),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: keep ? Colors.greenAccent : Colors.pinkAccent,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                     'Modifiée : ${_formatDate(item.modifiedDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Keep Toggle Action Button
                  ElevatedButton(
                    onPressed: () {
                      notifier.selectImageInSimilarGroup(group, item);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: keep ? Colors.greenAccent : Colors.white.withOpacity(0.05),
                      foregroundColor: keep ? AppColors.obsidian : Colors.white70,
                      elevation: keep ? 4 : 0,
                      shadowColor: Colors.greenAccent.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        side: BorderSide(
                          color: keep ? Colors.transparent : Colors.white10,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          keep ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          keep ? 'CONSERVER CETTE PHOTO' : 'CHOISIR CETTE PHOTO',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
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

  /// Renders either a gorgeous gradient for simulated mock images, or uses Image.file for real paths.
  Widget _renderImagePreview(String path) {
    if (path.startsWith('mock_sunset')) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF512F), // Vibrant sunset orange
              Color(0xFFFF8C00), // Sunshine gold
              Color(0xFFDD2476), // Electric pink
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wb_sunny_rounded,
                size: 64,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Aperçu Sunset Rafale',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'SIMULATION PHOTO HAUTE FIDÉLITÉ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (path.startsWith('mock_selfie')) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8A2387), // Deep purple
              Color(0xFFE94057), // Neon pink-red
              Color(0xFFF27121), // Sunshine coral
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.face_retouching_natural_rounded,
                size: 64,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Aperçu Selfie Rafale',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'SIMULATION PHOTO HAUTE FIDÉLITÉ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Physical file
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Graceful fallback for physical file read failures
          return Container(
            color: Colors.white.withOpacity(0.01),
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
            ),
          );
        },
      );
    }
  }

  String _formatBytes(double bytes) {
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
