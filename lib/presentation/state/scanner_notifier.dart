import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/file_item.dart';
import '../../domain/repositories/file_scanner_repository.dart';
import '../../domain/usecases/scan_directory_usecase.dart';
import '../../domain/usecases/delete_files_usecase.dart';
import '../../domain/usecases/get_storage_space_usecase.dart';

/// Presentation State Manager for the duplicate scanner application.
/// Uses standard Flutter [ChangeNotifier] to ensure decoupled, reactive UI updates.
class ScannerNotifier extends ChangeNotifier {
  final ScanDirectoryUseCase _scanDirectoryUseCase;
  final DeleteFilesUseCase _deleteFilesUseCase;
  final GetStorageSpaceUseCase _getStorageSpaceUseCase;

  String? _selectedDirectory;
  StorageSpaceInfo? _storageSpaceInfo;
  ScanProgress? _scanProgress;
  DeletionResult? _deletionResult;
  
  bool _isScanning = false;
  bool _isDeleting = false;
  List<DuplicateGroup> _duplicates = [];
  String _statusMessage = 'Prêt à numériser';
  StreamSubscription<ScanProgress>? _scanSubscription;
  StreamSubscription<DeletionResult>? _deletionSubscription;

  ScannerNotifier({
    required ScanDirectoryUseCase scanDirectoryUseCase,
    required DeleteFilesUseCase deleteFilesUseCase,
    required GetStorageSpaceUseCase getStorageSpaceUseCase,
  })  : _scanDirectoryUseCase = scanDirectoryUseCase,
        _deleteFilesUseCase = deleteFilesUseCase,
        _getStorageSpaceUseCase = getStorageSpaceUseCase {
    fetchStorageSpace();
  }

  // Getters
  String? get selectedDirectory => _selectedDirectory;
  StorageSpaceInfo? get storageSpaceInfo => _storageSpaceInfo;
  ScanProgress? get scanProgress => _scanProgress;
  DeletionResult? get deletionResult => _deletionResult;
  bool get isScanning => _isScanning;
  bool get isDeleting => _isDeleting;
  List<DuplicateGroup> get duplicates => _duplicates;
  String get statusMessage => _statusMessage;

  /// Retrieves the device storage info.
  Future<void> fetchStorageSpace() async {
    try {
      _storageSpaceInfo = await _getStorageSpaceUseCase();
      notifyListeners();
    } catch (_) {
      // Gracefully handle query failures
    }
  }

  /// Sets the directory chosen by the user.
  void selectDirectory(String path) {
    _selectedDirectory = path;
    _duplicates = [];
    _scanProgress = null;
    _deletionResult = null;
    _statusMessage = 'Dossier sélectionné, prêt à analyser';
    notifyListeners();
  }

  /// Starts the scanning engine in the background Isolate.
  void startScan() {
    final path = _selectedDirectory;
    if (path == null || _isScanning || _isDeleting) return;

    _isScanning = true;
    _duplicates = [];
    _deletionResult = null;
    _scanProgress = ScanProgress.initial();
    _statusMessage = 'Initialisation de l\'analyse...';
    notifyListeners();

    _scanSubscription?.cancel();
    _scanSubscription = _scanDirectoryUseCase(path).listen(
      (progress) {
        _scanProgress = progress;
        _duplicates = progress.duplicates;
        _statusMessage = progress.currentItemScanned;
        
        if (progress.isCompleted) {
          _isScanning = false;
          _statusMessage = 'Analyse terminée ! ${progress.duplicatesFound} doublons trouvés.';
        }
        notifyListeners();
      },
      onError: (error) {
        _isScanning = false;
        _statusMessage = 'Erreur pendant l\'analyse : $error';
        notifyListeners();
      },
      onDone: () {
        _isScanning = false;
        notifyListeners();
      },
    );
  }

  /// Cancels an ongoing scan and releases resources.
  void cancelScan() {
    _scanSubscription?.cancel();
    _isScanning = false;
    _statusMessage = 'Analyse annulée par l\'utilisateur';
    notifyListeners();
  }

  /// Toggles individual file selection for deletion in a duplicate group.
  void toggleFileSelection(FileItem file) {
    file.isSelected = !file.isSelected;
    notifyListeners();
  }

  /// Automatically selects files to delete in each duplicate group.
  /// Keeps one file intact (either oldest or newest based on [keepOldest]).
  void autoSelectDuplicates({bool keepOldest = true}) {
    for (var group in _duplicates) {
      if (group.files.length <= 1) continue;

      // Sort copies by modified date
      group.sortByDate(oldestFirst: keepOldest);

      // Keep the first file (index 0) intact, select all others for deletion
      for (int i = 0; i < group.files.length; i++) {
        group.files[i].isSelected = (i > 0);
      }
    }
    notifyListeners();
  }

  /// Deselects all files across all groups.
  void clearAllSelection() {
    for (var group in _duplicates) {
      for (var file in group.files) {
        file.isSelected = false;
      }
    }
    notifyListeners();
  }

  /// Get the list of all files currently checked for deletion.
  List<FileItem> get selectedFilesToDelete {
    final List<FileItem> selected = [];
    for (var group in _duplicates) {
      for (var file in group.files) {
        if (file.isSelected) {
          selected.add(file);
        }
      }
    }
    return selected;
  }

  /// Calculates the total size of all currently selected duplicate files.
  int get selectedDeletionSize {
    return selectedFilesToDelete.fold(0, (sum, file) => sum + file.size);
  }

  /// Deletes the selected duplicate files.
  Future<void> executeDeletion() async {
    final filesToDelete = selectedFilesToDelete;
    if (filesToDelete.isEmpty || _isScanning || _isDeleting) return;

    _isDeleting = true;
    _statusMessage = 'Suppression en cours...';
    notifyListeners();

    _deletionSubscription?.cancel();
    _deletionSubscription = _deleteFilesUseCase(filesToDelete).listen(
      (result) async {
        _deletionResult = result;
        if (result.isCompleted) {
          _isDeleting = false;
          _statusMessage = 'Nettoyage terminé ! Espace récupéré : ${_formatSize(result.spaceReclaimed.toDouble())}';
          
          // Re-fetch disk space after deletion
          await fetchStorageSpace();

          // Filter out deleted files from our local state
          _removeDeletedFiles(filesToDelete);
        }
        notifyListeners();
      },
      onError: (error) {
        _isDeleting = false;
        _statusMessage = 'Erreur pendant le nettoyage : $error';
        notifyListeners();
      },
      onDone: () {
        _isDeleting = false;
        notifyListeners();
      },
    );
  }

  /// Clean up local files memory structure after physical deletion
  void _removeDeletedFiles(List<FileItem> deletedFiles) {
    final Set<String> deletedPaths = deletedFiles.map((f) => f.path).toSet();

    final List<DuplicateGroup> updatedGroups = [];
    for (var group in _duplicates) {
      final List<FileItem> remainingFiles = group.files.where((f) => !deletedPaths.contains(f.path)).toList();
      
      // If there's still more than 1 file in the group, it's still a duplicate group
      if (remainingFiles.length > 1) {
        updatedGroups.add(DuplicateGroup(
          hash: group.hash,
          fileSize: group.fileSize,
          files: remainingFiles,
        ));
      }
    }

    _duplicates = updatedGroups;
    notifyListeners();
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

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _deletionSubscription?.cancel();
    super.dispose();
  }
}
