import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import '../../domain/entities/file_item.dart';

/// Message sent from the main thread to the Isolate to request a scan.
class IsolateScanRequest {
  final String directoryPath;
  final SendPort replyPort;

  IsolateScanRequest({
    required this.directoryPath,
    required this.replyPort,
  });
}

/// Message sent from the Isolate back to the main thread with progress.
class IsolateScanUpdate {
  final double percentage;
  final int filesScanned;
  final int duplicatesFound;
  final int totalDuplicateSize;
  final String currentItemScanned;
  final List<DuplicateGroup> duplicates;
  final bool isCompleted;

  IsolateScanUpdate({
    required this.percentage,
    required this.filesScanned,
    required this.duplicatesFound,
    required this.totalDuplicateSize,
    required this.currentItemScanned,
    required this.duplicates,
    this.isCompleted = false,
  });
}

/// Entry point for the background Isolate.
/// Must be a top-level function or a static method.
Future<void> scanIsolateEntry(SendPort mainSendPort) async {
  final receivePort = ReceivePort();
  // Send the Isolate's own SendPort to the main thread to establish communication
  mainSendPort.send(receivePort.sendPort);

  await for (var message in receivePort) {
    if (message is IsolateScanRequest) {
      final String dirPath = message.directoryPath;
      final SendPort replyPort = message.replyPort;

      try {
        final List<File> allFiles = [];
        final Directory rootDir = Directory(dirPath);

        // Step 1: Collect files recursively, avoiding system folders and catching errors
        _traverse(rootDir, allFiles);

        final totalFiles = allFiles.length;
        if (totalFiles == 0) {
          replyPort.send(IsolateScanUpdate(
            percentage: 1.0,
            filesScanned: 0,
            duplicatesFound: 0,
            totalDuplicateSize: 0,
            currentItemScanned: 'Aucun fichier trouvé',
            duplicates: [],
            isCompleted: true,
          ));
          continue;
        }

        // Step 2: Group by size. (Huge performance optimization: only hash files sharing identical size)
        final Map<int, List<File>> filesBySize = {};
        for (var file in allFiles) {
          try {
            final size = file.lengthSync();
            filesBySize.putIfAbsent(size, () => []).add(file);
          } catch (_) {
            // Skip files that cannot be read/sized
          }
        }

        // Filter to keep only sizes that have 2 or more files
        final potentialDuplicates = filesBySize.entries
            .where((entry) => entry.value.length > 1)
            .toList();

        final int totalPotentialFiles = potentialDuplicates.fold(0, (sum, entry) => sum + entry.value.length);
        int processedPotentialFiles = 0;

        final Map<String, List<FileItem>> duplicatesMap = {};

        // Step 3: Compute MD5 hash only for files of identical sizes
        for (var entry in potentialDuplicates) {
          final int size = entry.key;
          final List<File> files = entry.value;

          for (var file in files) {
            final String path = file.path;
            final String name = path.split(Platform.pathSeparator).last;
            
            // Notify main thread of progress
            final double progressPercentage = totalPotentialFiles > 0
                ? (processedPotentialFiles / totalPotentialFiles) * 0.95
                : 0.0;

            replyPort.send(IsolateScanUpdate(
              percentage: progressPercentage,
              filesScanned: processedPotentialFiles,
              duplicatesFound: _countDuplicates(duplicatesMap),
              totalDuplicateSize: _calculateWastedSize(duplicatesMap),
              currentItemScanned: name,
              duplicates: _convertToGroups(duplicatesMap),
            ));

            String fileHash = '';
            try {
              // Read chunk by chunk asynchronously to be memory efficient (does not load full file in RAM)
              final FileStat stat = file.statSync();
              final stream = file.openRead();
              final hashOutput = await md5.bind(stream).first;
              fileHash = hashOutput.toString();
              
              if (fileHash.isNotEmpty) {
                final item = FileItem(
                  path: path,
                  name: name,
                  size: size,
                  hash: fileHash,
                  modifiedDate: stat.modified,
                );
                duplicatesMap.putIfAbsent(fileHash, () => []).add(item);
              }
            } catch (_) {
              // Gracefully handle files that locked up or failed during read
            }

            processedPotentialFiles++;
          }
        }

        // Filter out groups with only 1 file (false duplicates because of hash collisions/failures)
        final finalDuplicates = _convertToGroups(duplicatesMap);
        final int totalDupSize = finalDuplicates.fold(0, (sum, g) => sum + g.wastedSize);
        final int totalDupCount = finalDuplicates.fold(0, (sum, g) => sum + g.files.length);

        replyPort.send(IsolateScanUpdate(
          percentage: 1.0,
          filesScanned: totalFiles,
          duplicatesFound: totalDupCount,
          totalDuplicateSize: totalDupSize,
          currentItemScanned: 'Scan terminé avec succès !',
          duplicates: finalDuplicates,
          isCompleted: true,
        ));
      } catch (e) {
        // Fallback error reporting
        replyPort.send(IsolateScanUpdate(
          percentage: 1.0,
          filesScanned: 0,
          duplicatesFound: 0,
          totalDuplicateSize: 0,
          currentItemScanned: 'Erreur lors du scan : ${e.toString()}',
          duplicates: [],
          isCompleted: true,
        ));
      }
    }
  }
}

/// Helper method to check if a file or directory should be excluded.
bool _shouldExclude(String absolutePath) {
  // Define a comprehensive blacklist of system, cache, development, and temporary directories in lowercase.
  const Set<String> blacklist = {
    // Windows
    'windows',
    'program files',
    'program files (x86)',
    'programdata',
    'appdata',
    'recovery',
    'system volume information',
    '\$recycle.bin',
    '\$winreagent',
    // Android/Linux
    'system',
    'vendor',
    'proc',
    'sys',
    'dev',
    // Development caches & version control
    'node_modules',
    '.git',
    '.gradle',
    '.pub-cache',
    '.idea',
    '.vscode',
    'build',
    'dist',
    '.dart_tool',
  };

  // Normalize path separators to forward slash and convert to lowercase
  final String normalized = absolutePath.replaceAll('\\', '/').toLowerCase();
  
  // Split path into individual components/segments
  final List<String> segments = normalized.split('/');
  if (segments.isEmpty) {
    return false;
  }

  // Get the last non-empty segment (name of the file or directory)
  String name = '';
  int lastIdx = -1;
  for (int i = segments.length - 1; i >= 0; i--) {
    if (segments[i].isNotEmpty) {
      name = segments[i];
      lastIdx = i;
      break;
    }
  }

  if (name.isEmpty) {
    return false;
  }

  // Hidden directories or files: any whose name starts with a dot '.'
  if (name.startsWith('.')) {
    return true;
  }

  // Check case-insensitive lookup
  if (blacklist.contains(name)) {
    return true;
  }

  // Special check for composite Android path 'data/data'
  if (name == 'data' && lastIdx > 0) {
    String parentSegment = '';
    for (int i = lastIdx - 1; i >= 0; i--) {
      if (segments[i].isNotEmpty) {
        parentSegment = segments[i];
        break;
      }
    }
    if (parentSegment == 'data') {
      return true;
    }
  }

  return false;
}

/// Set of whitelisted standard user file extensions (lowercase).
const Set<String> _allowedUserExtensions = {
  // Images
  'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tiff', 'tif', 'svg', 'heic', 'heif',
  
  // Videos
  'mp4', 'mkv', 'avi', 'mov', 'flv', 'webm', 'wmv', 'm4v', '3gp',
  
  // Audio
  'mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a', 'wma', 'opus',
  
  // Documents
  'pdf', 'txt', 'rtf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'ods', 'odp', 'csv',
  
  // Archives / Compressed
  'zip', 'rar', '7z', 'tar', 'gz', 'bz2',
};

/// Helper method to check if a file has a whitelisted user file extension.
bool _isUserFile(String filePath) {
  final int dotIdx = filePath.lastIndexOf('.');
  if (dotIdx == -1 || dotIdx == filePath.length - 1) {
    return false; // No extension or trailing dot
  }
  final String ext = filePath.substring(dotIdx + 1).toLowerCase();
  return _allowedUserExtensions.contains(ext);
}

/// Recursively traverses directories, avoiding protected system folders and hidden files.
void _traverse(Directory dir, List<File> filesList) {
  if (_shouldExclude(dir.path)) {
    return;
  }
  try {
    final List<FileSystemEntity> entities = dir.listSync(recursive: false, followLinks: false);
    for (var entity in entities) {
      if (entity is File) {
        if (!_shouldExclude(entity.path) && _isUserFile(entity.path)) {
          filesList.add(entity);
        }
      } else if (entity is Directory) {
        if (!_shouldExclude(entity.path)) {
          _traverse(entity, filesList);
        }
      }
    }
  } catch (_) {
    // Gracefully ignore permission denied errors or empty directories
  }
}

/// Count total duplicates currently stored in map.
int _countDuplicates(Map<String, List<FileItem>> map) {
  int count = 0;
  for (var list in map.values) {
    if (list.length > 1) {
      count += list.length;
    }
  }
  return count;
}

/// Computes the total wasted storage size of duplicate files.
int _calculateWastedSize(Map<String, List<FileItem>> map) {
  int totalWasted = 0;
  for (var list in map.values) {
    if (list.length > 1) {
      final size = list.first.size;
      totalWasted += size * (list.length - 1);
    }
  }
  return totalWasted;
}

/// Converts duplicates map into a sorted list of [DuplicateGroup]s.
List<DuplicateGroup> _convertToGroups(Map<String, List<FileItem>> map) {
  final List<DuplicateGroup> groups = [];
  for (var entry in map.entries) {
    if (entry.value.length > 1) {
      groups.add(DuplicateGroup(
        hash: entry.key,
        fileSize: entry.value.first.size,
        files: entry.value,
      ));
    }
  }
  // Sort groups by wasted size descending
  groups.sort((a, b) => b.wastedSize.compareTo(a.wastedSize));
  return groups;
}
