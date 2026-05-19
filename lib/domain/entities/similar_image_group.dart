import 'file_item.dart';

/// Represents a group of contextually or visually similar images (e.g. burst shots).
class SimilarImageGroup {
  final String id;
  final String reason;
  final List<FileItem> images;

  SimilarImageGroup({
    required this.id,
    required this.reason,
    required this.images,
  });

  /// The total storage space occupied by the duplicate images that could be deleted.
  /// Typically we keep 1 image and delete the rest.
  int get potentialSavings {
    if (images.length <= 1) return 0;
    // We sort images such that the best/kept one is first (not selected for deletion),
    // and all selected ones are deleted.
    return images
        .where((img) => img.isSelected)
        .fold(0, (sum, img) => sum + img.size);
  }

  /// Evaluates and pre-selects the best image to KEEP (making isSelected = false),
  /// and selects the other similar ones for DELETION (making isSelected = true).
  ///
  /// Criteria for the best image:
  /// 1. Higher file size (usually indicates better resolution / less compression).
  /// 2. Older creation date (original vs modified copy).
  void autoSelectBest() {
    if (images.length <= 1) return;

    // Sort: Best image first
    images.sort((a, b) {
      // First try size (larger is usually better resolution/quality)
      final sizeCompare = b.size.compareTo(a.size);
      if (sizeCompare != 0) return sizeCompare;

      // If sizes are identical, prefer the older file (more likely to be original)
      return a.modifiedDate.compareTo(b.modifiedDate);
    });

    // Keep the first one, mark all others for deletion
    images[0].isSelected = false;
    for (int i = 1; i < images.length; i++) {
      images[i].isSelected = true;
    }
  }
}
