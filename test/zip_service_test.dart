import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fastshare/core/zip_service.dart';
import 'package:archive/archive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ZipService Tests', () {
    late Directory tempDir;
    late ZipService zipService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('zip_test_');
      zipService = ZipService();
    });

    tearDown(() async {
      await zipService.cleanup();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('createZip creates a valid ZIP file from multiple source files',
        () async {
      // 1. Create test files
      final file1 = File('${tempDir.path}/test1.txt');
      await file1.writeAsString('Hello World Content');

      final file2 = File('${tempDir.path}/test2.txt');
      await file2.writeAsString('Second file content for testing');

      // 2. Prepare PlatformFiles
      final items = [
        PlatformFile(
          name: 'test1.txt',
          path: file1.path,
          size: await file1.length(),
        ),
        PlatformFile(
          name: 'test2.txt',
          path: file2.path,
          size: await file2.length(),
        ),
      ];

      // 3. Create ZIP
      final zipPath = await zipService.createZip(items);

      // 4. Verify ZIP existence
      final zipFile = File(zipPath);
      expect(await zipFile.exists(), isTrue);
      expect(await zipFile.length(), greaterThan(0));

      // 5. Verify ZIP content using archive package
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      expect(archive.length, equals(2));

      final entry1 = archive.findFile('test1.txt');
      expect(entry1, isNotNull);
      expect(String.fromCharCodes(entry1!.content as List<int>),
          equals('Hello World Content'));

      final entry2 = archive.findFile('test2.txt');
      expect(entry2, isNotNull);
      expect(String.fromCharCodes(entry2!.content as List<int>),
          equals('Second file content for testing'));

      print('ZIP Test Passed: $zipPath size: ${await zipFile.length()} bytes');
    });
  });
}
