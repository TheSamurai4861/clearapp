import '../repositories/file_scanner_repository.dart';

class GetStorageSpaceUseCase {
  final FileScannerRepository _repository;

  GetStorageSpaceUseCase(this._repository);

  Future<StorageSpaceInfo> call() {
    return _repository.getStorageSpace();
  }
}
