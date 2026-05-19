import '../entities/file_item.dart';
import '../repositories/file_scanner_repository.dart';

class DeleteFilesUseCase {
  final FileScannerRepository _repository;

  DeleteFilesUseCase(this._repository);

  Stream<DeletionResult> call(List<FileItem> files) {
    return _repository.deleteFiles(files);
  }
}
