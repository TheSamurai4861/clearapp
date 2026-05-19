import '../repositories/file_scanner_repository.dart';

class ScanDirectoryUseCase {
  final FileScannerRepository _repository;

  ScanDirectoryUseCase(this._repository);

  Stream<ScanProgress> call(String directoryPath) {
    return _repository.scanDirectory(directoryPath);
  }
}
