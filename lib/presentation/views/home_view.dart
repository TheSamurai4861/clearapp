import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../state/scanner_notifier.dart';
import '../widgets/glass_card.dart';
import '../widgets/storage_bar.dart';
import 'scan_view.dart';

/// The main entry view of ClearApp. Displays storage metrics and allows
/// selecting a target folder to clean duplicates. Adaptive for Windows & Android.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    // Refresh storage space when landing on home screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScannerNotifier>().fetchStorageSpace();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Safely handles directory selection with platform permissions (Android).
  Future<void> _pickDirectory(BuildContext context, ScannerNotifier notifier) async {
    try {
      // 1. Android Permission Request
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Accès au stockage requis pour analyser les doublons.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }

      // 2. Pick directory
      final String? directory = await FilePicker.getDirectoryPath(
        dialogTitle: 'Sélectionner le dossier à analyser',
      );

      if (directory != null) {
        notifier.selectDirectory(directory);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de sélection : ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Selects the entire system root directory depending on OS.
  Future<void> _selectSystemRoot(BuildContext context, ScannerNotifier notifier) async {
    try {
      // 1. Android Permission Request
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Accès au stockage requis pour analyser l\'appareil.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }

      String rootPath = '/';
      if (Platform.isWindows) {
        rootPath = 'C:\\';
      } else if (Platform.isAndroid) {
        rootPath = '/storage/emulated/0';
      } else if (Platform.isIOS) {
        final docsDir = await getApplicationDocumentsDirectory();
        rootPath = docsDir.path;
      }
      notifier.selectDirectory(rootPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de sélection système : ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 700;

    return Scaffold(
      body: Stack(
        children: [
          // Background rich gradient Obsidian
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.obsidianGradient,
            ),
          ),

          // Cyberpunk glowing ambient background spheres
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.electricBlue.withOpacity(0.08),
              ),
              child: ClipRRect(
                child: ImageFiltered(
                  imageFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.dstOut,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonPurple.withOpacity(0.08),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Consumer<ScannerNotifier>(
                  builder: (context, notifier, child) {
                    final info = notifier.storageSpaceInfo;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header section
                        _buildHeader(context),
                        
                        const SizedBox(height: AppSpacing.xl),

                        // Storage Metrics card
                        if (info != null)
                          GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: StorageBar(
                              totalBytes: info.totalBytes,
                              usedBytes: info.usedBytes,
                              duplicateBytes: 0.0, // No duplicates scanned yet
                            ),
                          )
                        else
                          const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.electricBlue,
                            ),
                          ),

                        const SizedBox(height: AppSpacing.xl),

                        // Scan folder selection card
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                // Palpitating cleaner icon
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    final scale = 1.0 + (_pulseController.value * 0.06);
                                    return Transform.scale(
                                      scale: scale,
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.electricBlue.withOpacity(0.05),
                                          border: Border.all(
                                            color: AppColors.electricBlue.withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.electricBlue.withOpacity(0.15 * _pulseController.value),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.folder_copy_outlined,
                                          color: AppColors.electricBlue,
                                          size: 36,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  'Sélectionner le répertoire à nettoyer',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'ClearApp effectuera un scan en profondeur pour trouver les fichiers strictement identiques.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.xl),

                                // Pick Folder Buttons (Targeted or Entire PC)
                                Wrap(
                                  spacing: AppSpacing.md,
                                  runSpacing: AppSpacing.md,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.folder_open),
                                      label: Text(
                                        notifier.selectedDirectory != null
                                            ? 'Cibler un autre dossier'
                                            : 'Choisir un dossier',
                                      ),
                                      onPressed: () => _pickDirectory(context, notifier),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.electricBlue,
                                        side: const BorderSide(color: AppColors.electricBlue, width: 1.5),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg,
                                          vertical: AppSpacing.md,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      icon: Icon(
                                        Platform.isWindows
                                            ? Icons.computer_rounded
                                            : (Platform.isIOS
                                                ? Icons.phone_iphone_rounded
                                                : Icons.phone_android_rounded),
                                      ),
                                      label: Text(
                                        Platform.isWindows
                                            ? 'Analyser tout le PC'
                                            : (Platform.isIOS
                                                ? 'Analyser l\'appareil'
                                                : 'Analyser tout l\'appareil'),
                                      ),
                                      onPressed: () => _selectSystemRoot(context, notifier),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.neonPurple,
                                        foregroundColor: Colors.white,
                                        shadowColor: AppColors.neonPurple.withOpacity(0.4),
                                        elevation: 6,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg,
                                          vertical: AppSpacing.md,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Display selected path with glass card details
                                if (notifier.selectedDirectory != null) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.02),
                                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.polyline_outlined,
                                          color: AppColors.textSecondary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            notifier.selectedDirectory!,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  fontFamily: 'monospace',
                                                  color: AppColors.textPrimary,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xl),

                                  // Glowing Start Scan Button
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                      boxShadow: AppShadows.neonGlow,
                                    ),
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.youtube_searched_for),
                                      label: const Text('LANCER L\'ANALYSE'),
                                      onPressed: () {
                                        notifier.startScan();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const ScanView(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.electricBlue,
                                        foregroundColor: AppColors.obsidian,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xxl,
                                          vertical: AppSpacing.md,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: const Icon(
                  Icons.cleaning_services_rounded,
                  color: AppColors.obsidian,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ClearApp',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Nettoyeur de doublons premium',
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
        
        // Settings or Help icon
        IconButton(
          icon: const Icon(
            Icons.info_outline_rounded,
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            showAboutDialog(
              context: context,
              applicationName: 'ClearApp',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(
                Icons.cleaning_services_rounded,
                color: AppColors.electricBlue,
              ),
              children: [
                const Text(
                  'ClearApp est un outil moderne et performant pour nettoyer vos fichiers en double en toute sécurité sur Windows et Android.',
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
