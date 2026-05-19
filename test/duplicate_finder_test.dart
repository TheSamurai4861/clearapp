import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearapp/domain/entities/file_item.dart';
import 'package:clearapp/data/repositories/local_file_scanner_repository.dart';

void main() {
  group('LocalFileScannerRepository Integration Tests', () {
    late Directory tempDir;
    late LocalFileScannerRepository repository;

    setUp(() {
      // Create a unique temporary directory for each test run
      tempDir = Directory.systemTemp.createTempSync('clearapp_test_');
      repository = LocalFileScannerRepository();
    });

    tearDown(() {
      // Clean up the temporary directory after tests
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('Should accurately identify duplicate files based on content hash', () async {
      // 1. Arrange: Create test files
      // Group A duplicates: Two files with identical text content "HELLO"
      final fileA1 = File('${tempDir.path}/doc1.txt')..writeAsStringSync('HELLO');
      final fileA2 = File('${tempDir.path}/doc1_copy.txt')..writeAsStringSync('HELLO');

      // Group B duplicates: Two files with identical content "WORLD"
      final fileB1 = File('${tempDir.path}/note.pdf')..writeAsStringSync('WORLD');
      final fileB2 = File('${tempDir.path}/note_backup.pdf')..writeAsStringSync('WORLD');

      // Unique files:
      // Unique size and content
      final fileUnique1 = File('${tempDir.path}/unique.docx')..writeAsStringSync('UNIQUE_CONTENT_LOREM_IPSUM');
      // Identical size to Group A ("HELLO" is 5 bytes) but different content ("12345")
      final fileUnique2 = File('${tempDir.path}/different_content_same_size.txt')..writeAsStringSync('12345');

      // 2. Act: Execute scanning stream
      final scanStream = repository.scanDirectory(tempDir.path);
      
      // Wait for the stream to complete and collect final progress update
      final scanResult = await scanStream.firstWhere((progress) => progress.isCompleted);

      // 3. Assert: Verify findings
      expect(scanResult.filesScanned, equals(6)); // Total files in directory
      expect(scanResult.duplicates.length, equals(2)); // Should find 2 duplicate groups

      // Group A Verification (MD5 of "HELLO" is 8b1a9953c4611296a827abf8c47804d7)
      final groupA = scanResult.duplicates.firstWhere(
        (g) => g.fileSize == 5 && g.files.any((f) => f.name == 'doc1.txt'),
      );
      expect(groupA.files.length, equals(2));
      final groupAFiles = groupA.files.map((f) => f.name).toList();
      expect(groupAFiles, contains('doc1.txt'));
      expect(groupAFiles, contains('doc1_copy.txt'));
      expect(groupA.wastedSize, equals(5)); // 5 bytes wasted (1 duplicate copy)

      // Group B Verification (MD5 of "WORLD" is f5a7924e621e84c9280a9a27e1bcb7f6)
      final groupB = scanResult.duplicates.firstWhere(
        (g) => g.fileSize == 5 && g.files.any((f) => f.name == 'note.pdf'),
      );
      expect(groupB.files.length, equals(2));
      final groupBFiles = groupB.files.map((f) => f.name).toList();
      expect(groupBFiles, contains('note.pdf'));
      expect(groupBFiles, contains('note_backup.pdf'));

      // Check unique files are NOT flagged in duplicates
      final allDuplicateFiles = scanResult.duplicates.expand((g) => g.files).map((f) => f.name).toSet();
      expect(allDuplicateFiles, isNot(contains('unique.docx')));
      expect(allDuplicateFiles, isNot(contains('different_content_same_size.txt')));
    });

    test('Should successfully delete selected files and reclaim correct space', () async {
      // Arrange: Create duplicate files
      final file1 = File('${tempDir.path}/test1.txt')..writeAsStringSync('DUPLICATE_DATA');
      final file2 = File('${tempDir.path}/test2.txt')..writeAsStringSync('DUPLICATE_DATA');
      
      final scanStream = repository.scanDirectory(tempDir.path);
      final scanResult = await scanStream.firstWhere((progress) => progress.isCompleted);
      
      expect(scanResult.duplicates.length, equals(1));
      final group = scanResult.duplicates.first;
      final fileItemToDelete = group.files.firstWhere((f) => f.name == 'test2.txt');

      // Act: Delete test2.txt
      final deletionStream = repository.deleteFiles([fileItemToDelete]);
      final deletionResult = await deletionStream.firstWhere((res) => res.isCompleted);

      // Assert
      expect(deletionResult.filesDeleted, equals(1));
      expect(deletionResult.spaceReclaimed, equals(fileItemToDelete.size));
      
      // Verify file is physically removed from disk
      expect(await file2.exists(), isFalse);
      expect(await file1.exists(), isTrue); // Keep original intact
    });

    test('Should ignore files inside system, cache, and hidden directories', () async {
      // Arrange: Create valid files in root
      final fileValid1 = File('${tempDir.path}/valid1.txt')..writeAsStringSync('VALID_DUPLICATE');
      final fileValid2 = File('${tempDir.path}/valid2.txt')..writeAsStringSync('VALID_DUPLICATE');

      // Create blacklisted directories and write duplicate-content files inside them
      final excludedPaths = [
        '${tempDir.path}/Windows',
        '${tempDir.path}/program files',
        '${tempDir.path}/AppData',
        '${tempDir.path}/.git',
        '${tempDir.path}/node_modules',
        '${tempDir.path}/.cache',
      ];

      for (var path in excludedPaths) {
        final dir = Directory(path);
        dir.createSync(recursive: true);
        final file = File('${dir.path}/sys_dup.txt');
        file.writeAsStringSync('VALID_DUPLICATE'); // identical content to trigger hash comparison
      }

      // Act: Run scanning stream
      final scanStream = repository.scanDirectory(tempDir.path);
      final scanResult = await scanStream.firstWhere((progress) => progress.isCompleted);

      // Assert: Verify only root files were scanned and reported
      // Root has 2 files. The system folders have 6 files which should be ignored.
      expect(scanResult.filesScanned, equals(2));
      expect(scanResult.duplicates.length, equals(1));

      final group = scanResult.duplicates.first;
      expect(group.files.length, equals(2));
      final fileNames = group.files.map((f) => f.name).toList();
      expect(fileNames, contains('valid1.txt'));
      expect(fileNames, contains('valid2.txt'));
      expect(fileNames, isNot(contains('sys_dup.txt')));
    });

    test('Should only scan whitelisted user file extensions (PDF, images, video, docs, etc.) and ignore program files', () async {
      // Arrange: Create valid user files
      final validUser1 = File('${tempDir.path}/photo.jpg')..writeAsStringSync('USER_MEDIA_DATA');
      final validUser2 = File('${tempDir.path}/photo_copy.png')..writeAsStringSync('USER_MEDIA_DATA');

      // Create files with invalid/non-user extensions but identical contents
      final invalidFiles = [
        File('${tempDir.path}/library.dll'),
        File('${tempDir.path}/executable.exe'),
        File('${tempDir.path}/system.sys'),
        File('${tempDir.path}/runtime.class'),
        File('${tempDir.path}/application.log'),
        File('${tempDir.path}/extensionless_file'), // no extension
      ];

      for (var file in invalidFiles) {
        file.writeAsStringSync('USER_MEDIA_DATA');
      }

      // Act: Run scanning stream
      final scanStream = repository.scanDirectory(tempDir.path);
      final scanResult = await scanStream.firstWhere((progress) => progress.isCompleted);

      // Assert: Verify only whitelisted files are scanned
      expect(scanResult.filesScanned, equals(2));
      expect(scanResult.duplicates.length, equals(1));

      final group = scanResult.duplicates.first;
      expect(group.files.length, equals(2));
      final fileNames = group.files.map((f) => f.name).toList();
      expect(fileNames, contains('photo.jpg'));
      expect(fileNames, contains('photo_copy.png'));
      
      // Ensure all other non-user formats were bypassed
      for (var file in invalidFiles) {
        final String baseName = file.path.split('/').last;
        expect(fileNames, isNot(contains(baseName)));
      }
    });
  });
}
