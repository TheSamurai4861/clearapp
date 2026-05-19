/// Represents a scanned file in the system.
/// This entity is a pure Dart representation of a file and has no dependencies on Flutter.
class FileItem {
  final String path;
  final String name;
  final int size;
  final String? hash;
  final DateTime modifiedDate;
  final String? id; // Null for local files, contains AssetEntity.id for Photo Library assets
  
  // Mutable state for selection during duplicate cleaning
  bool isSelected;

  FileItem({
    required this.path,
    required this.name,
    required this.size,
    this.hash,
    required this.modifiedDate,
    this.id,
    this.isSelected = false,
  });

  String get fileExtension {
    if (!name.contains('.')) return '';
    return name.split('.').last.toLowerCase();
  }

  /// Creates a copy of this [FileItem] with updated properties.
  FileItem copyWith({
    String? path,
    String? name,
    int? size,
    String? hash,
    DateTime? modifiedDate,
    String? id,
    bool? isSelected,
  }) {
    return FileItem(
      path: path ?? this.path,
      name: name ?? this.name,
      size: size ?? this.size,
      hash: hash ?? this.hash,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      id: id ?? this.id,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Represents a group of identical files sharing the same content hash.
class DuplicateGroup {
  final String hash;
  final int fileSize;
  final List<FileItem> files;

  DuplicateGroup({
    required this.hash,
    required this.fileSize,
    required this.files,
  });

  /// Total size wasted by duplicates in this group (i.e. size of all duplicate copies except one).
  int get wastedSize {
    if (files.length <= 1) return 0;
    return fileSize * (files.length - 1);
  }

  /// Sorts files by modified date so we can easily select older or newer files.
  void sortByDate({bool oldestFirst = true}) {
    files.sort((a, b) {
      if (oldestFirst) {
        return a.modifiedDate.compareTo(b.modifiedDate);
      } else {
        return b.modifiedDate.compareTo(a.modifiedDate);
      }
    });
  }
}
