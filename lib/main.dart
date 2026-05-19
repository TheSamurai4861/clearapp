import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/local_file_scanner_repository.dart';
import 'domain/usecases/delete_files_usecase.dart';
import 'domain/usecases/get_storage_space_usecase.dart';
import 'domain/usecases/scan_directory_usecase.dart';
import 'presentation/state/scanner_notifier.dart';
import 'presentation/views/home_view.dart';

import 'domain/usecases/scan_similar_photos_usecase.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Instantiate the Repository implementation (Data layer)
  final repository = LocalFileScannerRepository();

  // 2. Instantiate UseCases (Domain layer)
  final scanDirectoryUseCase = ScanDirectoryUseCase(repository);
  final deleteFilesUseCase = DeleteFilesUseCase(repository);
  final getStorageSpaceUseCase = GetStorageSpaceUseCase(repository);
  final scanSimilarPhotosUseCase = ScanSimilarPhotosUseCase(repository);

  runApp(
    // 3. Inject State Manager (Presentation layer) using Provider at the app root
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
}

class ClearApp extends StatelessWidget {
  const ClearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeView(),
    );
  }
}
