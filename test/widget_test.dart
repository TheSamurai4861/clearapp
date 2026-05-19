import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:clearapp/main.dart';
import 'package:clearapp/presentation/state/scanner_notifier.dart';
import 'package:clearapp/domain/repositories/file_scanner_repository.dart';
import 'package:clearapp/domain/entities/file_item.dart';
import 'package:clearapp/domain/usecases/scan_directory_usecase.dart';
import 'package:clearapp/domain/usecases/delete_files_usecase.dart';
import 'package:clearapp/domain/usecases/get_storage_space_usecase.dart';
import 'package:clearapp/domain/usecases/scan_similar_photos_usecase.dart';

/// A mock implementation of the FileScannerRepository that avoids any real
/// OS calls (like spawning PowerShell processes) during tests.
class FakeFileScannerRepository implements FileScannerRepository {
  @override
  Stream<ScanProgress> scanDirectory(String directoryPath) async* {
    yield ScanProgress.initial();
  }

  @override
  Stream<SimilarPhotosProgress> scanSimilarPhotos(String directoryPath) async* {
    yield SimilarPhotosProgress.initial();
  }

  @override
  Stream<SimilarPhotosProgress> scanPhotoLibrary() async* {
    yield SimilarPhotosProgress.initial();
  }

  @override
  Stream<DeletionResult> deleteFiles(List<FileItem> files) async* {
    yield DeletionResult(
      filesDeleted: files.length,
      totalFilesToDelete: files.length,
      spaceReclaimed: 0,
      isCompleted: true,
    );
  }

  @override
  Future<StorageSpaceInfo> getStorageSpace() async {
    return StorageSpaceInfo(
      totalBytes: 128.0 * 1024 * 1024 * 1024,
      usedBytes: 82.4 * 1024 * 1024 * 1024,
    );
  }
}

void main() {
  testWidgets('ClearApp initialization test', (WidgetTester tester) async {
    final repository = FakeFileScannerRepository();
    final scanDirectoryUseCase = ScanDirectoryUseCase(repository);
    final deleteFilesUseCase = DeleteFilesUseCase(repository);
    final getStorageSpaceUseCase = GetStorageSpaceUseCase(repository);
    final scanSimilarPhotosUseCase = ScanSimilarPhotosUseCase(repository);

    // Build our app and trigger a frame with the ScannerNotifier provider.
    await tester.pumpWidget(
      ChangeNotifierProvider<ScannerNotifier>(
        create: (_) => ScannerNotifier(
          scanDirectoryUseCase: scanDirectoryUseCase,
          deleteFilesUseCase: deleteFilesUseCase,
          getStorageSpaceUseCase: getStorageSpaceUseCase,
          scanSimilarPhotosUseCase: scanSimilarPhotosUseCase,
        ),
        child: const ClearApp(),
      ),
    );

    // Wait for the asynchronous initState calls (like fetchStorageSpace) to complete and render
    await tester.pump();

    // Verify that the title and key components of the premium UI are displayed.
    expect(find.text('ClearApp'), findsOneWidget);
    expect(find.text('Nettoyeur de doublons premium'), findsOneWidget);
    expect(find.text('Choisir un dossier'), findsOneWidget);
  });
}
