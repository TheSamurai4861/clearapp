import '../repositories/file_scanner_repository.dart';

/// Clean Architecture Use Case for scanning visually/temporally similar photos in a directory.
class ScanSimilarPhotosUseCase {
  final FileScannerRepository repository;

  ScanSimilarPhotosUseCase(this.repository);

  Stream<SimilarPhotosProgress> call(String directoryPath) {
    return repository.scanSimilarPhotos(directoryPath);
  }

  Stream<SimilarPhotosProgress> photoLibrary() {
    return repository.scanPhotoLibrary();
  }
}
