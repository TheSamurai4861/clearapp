import '../entities/file_item.dart';

/// Abstract contract for the file scanning and duplicate management.
/// Implementations of this contract reside in the Data layer.
abstract class FileScannerRepository {
  /// Scans a directory for files, calculates hashes, and groups duplicates.
  /// Emits real-time progress updates ([ScanProgress]).
  Stream<ScanProgress> scanDirectory(String directoryPath);

  /// Deletes a list of files from the storage.
  /// Returns a stream of [DeletionResult] tracking real-time deletion progress.
  Stream<DeletionResult> deleteFiles(List<FileItem> files);

  /// Retrieves the device storage space info (total, used).
  Future<StorageSpaceInfo> getStorageSpace();
}

/// Represents the real-time progress of a directory scan.
class ScanProgress {
  final double percentage; // 0.0 to 1.0
  final int filesScanned;
  final int duplicatesFound;
  final int totalDuplicateSize; // in bytes
  final String currentItemScanned;
  final List<DuplicateGroup> duplicates;
  final bool isCompleted;

  ScanProgress({
    required this.percentage,
    required this.filesScanned,
    required this.duplicatesFound,
    required this.totalDuplicateSize,
    required this.currentItemScanned,
    required this.duplicates,
    this.isCompleted = false,
  });

  factory ScanProgress.initial() {
    return ScanProgress(
      percentage: 0.0,
      filesScanned: 0,
      duplicatesFound: 0,
      totalDuplicateSize: 0,
      currentItemScanned: '',
      duplicates: [],
      isCompleted: false,
    );
  }
}

/// Represents the real-time status of file deletion.
class DeletionResult {
  final int filesDeleted;
  final int totalFilesToDelete;
  final int spaceReclaimed; // in bytes
  final bool isCompleted;

  DeletionResult({
    required this.filesDeleted,
    required this.totalFilesToDelete,
    required this.spaceReclaimed,
    this.isCompleted = false,
  });
}

/// Represents the storage details of the physical drive/device.
class StorageSpaceInfo {
  final double totalBytes;
  final double usedBytes;

  StorageSpaceInfo({
    required this.totalBytes,
    required this.usedBytes,
  });
}
