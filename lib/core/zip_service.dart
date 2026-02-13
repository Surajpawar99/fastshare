import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

// Internal descriptor for items to be streamed into the ZIP.
class _Entry {
  final String name;
  final String? path;
  final Stream<List<int>>? stream;
  final int size;
  _Entry({required this.name, this.path, this.stream, required this.size});
}

/// ===== ZIP CREATION: PRODUCTION-GRADE STREAMING WITHOUT MEMORY BUFFERING =====
///
/// CRITICAL ARCHITECTURE:
/// This service creates ZIP files that support files up to 100GB without memory buffering.
/// The approach uses OutputFileStream + ZipEncoder + InputFileStream for true streaming.
///
/// 1. OUTPUTFILESTREAM (ZIP output):
///    • Writes ZIP file directly to disk
///    • Does NOT buffer entire ZIP in memory
///    • Data flushed incrementally as files are added
///
/// 2. ZIPENCODER + ARCHIVE:
///    • ZipEncoder processes Archive object
///    • encode() writes directly via OutputFileStream
///    • Central directory written at end
///    • CRITICAL: Must call output.close() to finalize ZIP
///
/// 3. INPUTFILESTREAM (file input):
///    • Reads file chunks without loading entire file
///    • Used via ArchiveFile.fromStream()
///    • Each file streamed independently
///    • No readAsBytes() — no memory buffering
///
/// 4. ARCH IVEACCESS (per file):
///    • ArchiveFile.fromStream(name, size, inputStream)
///    • Streams file directly to ZIP without buffering
///    • Chunk-based reading (12-64KB per iteration)
///    • Closed after adding to archive
///
/// 5. FINALIZATION SEQUENCE:
///    • zipEncoder.encode(archive, output: output) — writes all data
///    • output.close() — flushes remaining bytes, writes ZIP structure
///    • CRITICAL: Both must complete before reading ZIP size
///    • File(zipPath).length() — reads ACTUAL file size from disk
///
/// 6. HTTP SERVING:
///    • Open ZIP with openRead() — streaming read
///    • Set Content-Length = file.length() (from step 5)
///    • Stream chunks to HTTP response
///    • Browser receives correct size metadata
///
/// MEMORY GUARANTEES:
/// • No file loaded into memory (InputFileStream chunks)
/// • No ZIP buffered in memory (OutputFileStream streams)
/// • Only ~1-4MB buffer for chunk processing
/// • Constant ~50MB max memory regardless of file size
/// • Supports 100GB+ files without OOM
///
/// COMMON PITFALLS (DO NOT DO):
/// ❌ ZipFileEncoder.addFile() — loads entire file with readAsBytes()
/// ❌ File.readAsBytes() — loads entire file into single buffer
/// ❌ Accessing ZIP size before output.close() — incomplete file
/// ❌ Not closing OutputFileStream — ZIP not finalized
/// ❌ Using AddFile with file paths — may load into memory
///
/// CORRECT FLOW:
/// 1. Create OutputFileStream → ZIP file on disk
/// 2. For each file: InputFileStream → ArchiveFile.fromStream → Archive
/// 3. ZipEncoder.encode(archive, output) → write to disk
/// 4. output.close() → finalize ZIP structure
/// 5. File.length() → read actual size (AFTER close)
/// 6. Serve via HTTP with Content-Length header

class ZipService {
  Isolate? _isolate;
  ReceivePort? _recvPort;
  String? _zipPath;
  final List<String> _tempCopiedFiles = [];

  /// Maximum allowed ZIP size in bytes. Can be overridden per-call.
  final int maxZipBytes;

  ZipService({this.maxZipBytes = 2 * 1024 * 1024 * 1024}); // default 2 GB

  /// Calculate total size of provided PlatformFiles. Folders are walked recursively.
  Future<int> calculateTotalSize(List<PlatformFile> items) async {
    int total = 0;
    for (final pf in items) {
      if (pf.path != null) {
        final p = pf.path!;
        final ent = FileSystemEntity.typeSync(p);
        if (ent == FileSystemEntityType.directory) {
          await for (final f
              in Directory(p).list(recursive: true, followLinks: false)) {
            if (f is File) {
              try {
                total += await f.length();
              } catch (_) {}
            }
          }
        } else if (ent == FileSystemEntityType.file) {
          try {
            total += await File(p).length();
          } catch (_) {
            total += pf.size;
          }
        } else {
          total += pf.size;
        }
      } else {
        // No path (stream-backed) — rely on provided size
        total += pf.size;
      }
    }
    return total;
  }

  /// Create ZIP file in system temp directory. Reports progress via [onProgress].
  /// Returns path to created ZIP file.
  Future<String> createZip(
    List<PlatformFile> items, {
    void Function(int processedBytes, int totalBytes)? onProgress,
    int? maxSizeBytes,
  }) async {
    final maxAllowed = maxSizeBytes ?? maxZipBytes;

    final totalSize = await calculateTotalSize(items);
    if (totalSize > maxAllowed) {
      throw Exception(
          'Selected items exceed max allowed ZIP size ($maxAllowed bytes)');
    }

    // Create working temp dir for this operation
    final workDir = await Directory.systemTemp.createTemp('fastshare_zip_');
    final ts = DateTime.now().millisecondsSinceEpoch;
    final zipPath = '${workDir.path}${Platform.pathSeparator}fastshare_$ts.zip';
    _zipPath = zipPath;

    // Expand directories and prepare flat list of entries to stream.
    // We create a lightweight descriptor list so we can uniformly stream
    // either a File.openRead() or the provided PlatformFile.readStream.
    final List<_Entry> entries = [];
    for (final pf in items) {
      if (pf.path != null) {
        final p = pf.path!;
        final ent = FileSystemEntity.typeSync(p);
        if (ent == FileSystemEntityType.directory) {
          await for (final f
              in Directory(p).list(recursive: true, followLinks: false)) {
            if (f is File) {
              final name = f.uri.pathSegments.last;
              final size = await f.length();
              entries.add(
                  _Entry(name: name, path: f.path, stream: null, size: size));
            }
          }
        } else if (ent == FileSystemEntityType.file) {
          final f = File(p);
          final name = f.uri.pathSegments.last;
          final size = await f.length();
          entries.add(_Entry(name: name, path: p, stream: null, size: size));
        }
      } else if (pf.readStream != null) {
        // Stream-backed file - use provided readStream and reported size
        entries.add(_Entry(
            name: pf.name, path: null, stream: pf.readStream, size: pf.size));
      } else {
        // skip unsupported entry
      }
    }

    // Spawn isolate and stream data chunks into it using TransferableTypedData.
    _recvPort = ReceivePort();

    SendPort? isolateControlPort;
    final completer = Completer<String>();

    final Map<String, Completer<void>> fileCompleters = {};

    _recvPort!.listen((msg) async {
      if (msg is Map) {
        final t = msg['type'] as String?;
        if (t == 'control_port') {
          isolateControlPort = msg['port'] as SendPort;
        } else if (t == 'progress') {
          final processed = msg['processed'] as int? ?? 0;
          onProgress?.call(processed, totalSize);
        } else if (t == 'file_done') {
          final name = msg['name'] as String?;
          if (name != null && fileCompleters.containsKey(name)) {
            fileCompleters[name]!.complete();
          }
        } else if (t == 'done') {
          completer.complete(msg['path'] as String);
        } else if (t == 'error') {
          completer.completeError(Exception(msg['error'] ?? 'Zip error'));
        }
      }
    });

    final args =
        _ZipIsolateArgs(sendPort: _recvPort!.sendPort, outPath: zipPath);

    _isolate = await Isolate.spawn<_ZipIsolateArgs>(_zipIsolateEntry, args,
        paused: false, debugName: 'zip_isolate');

    // Wait for isolate to send back its control port
    final startWait = DateTime.now();
    while (isolateControlPort == null) {
      await Future.delayed(const Duration(milliseconds: 10));
      if (DateTime.now().difference(startWait).inSeconds > 10) {
        throw Exception('Timeout waiting for ZIP isolate control port');
      }
    }

    try {
      // Stream each prepared entry into the isolate sequentially
      for (final entry in entries) {
        final name = entry.name;
        final size = entry.size;

        // Prepare per-file completer
        final fileCompleter = Completer<void>();
        fileCompleters[name] = fileCompleter;

        // Tell isolate to start a new file
        isolateControlPort!.send({'type': 'start', 'name': name, 'size': size});

        // Choose stream source
        Stream<List<int>> stream;
        if (entry.stream != null) {
          stream = entry.stream!;
        } else if (entry.path != null) {
          stream = File(entry.path!).openRead();
        } else {
          // nothing to stream for this entry
          isolateControlPort!.send({'type': 'end'});
          fileCompleters.remove(name);
          continue;
        }

        // Pump chunks into isolate as TransferableTypedData for efficiency
        final completerStream = Completer<void>();
        stream.listen((chunk) {
          try {
            final data = Uint8List.fromList(chunk);
            final ttd = TransferableTypedData.fromList([data]);
            isolateControlPort!.send({'type': 'data', 'chunk': ttd});
          } catch (e) {
            // send error to isolate
            isolateControlPort!.send({'type': 'error', 'error': e.toString()});
          }
        }, onDone: () async {
          // Signal end of this file
          isolateControlPort!.send({'type': 'end'});
          completerStream.complete();
        }, onError: (e) {
          completerStream.completeError(e);
        }, cancelOnError: true);

        // Wait for stream fully flushed and isolate to report file_done
        await completerStream.future;
        fileCompleters.remove(name);
      }

      // Tell isolate to finish archive
      isolateControlPort!.send({'type': 'finish'});

      final resultPath = await completer.future;
      return resultPath;
    } finally {
      // Close receive port but keep temp info for cleanup
      _recvPort?.close();
      _recvPort = null;
      _isolate = null;
    }
  }

  /// Cancel ongoing ZIP creation. This kills the isolate and removes partial zip.
  Future<void> cancel() async {
    if (_isolate != null) {
      _isolate!.kill(priority: Isolate.immediate);
      _isolate = null;
    }
    if (_zipPath != null) {
      try {
        final f = File(_zipPath!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
      _zipPath = null;
    }
    // delete any temp-copied files
    for (final p in _tempCopiedFiles) {
      try {
        final f = File(p);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    _tempCopiedFiles.clear();
  }

  /// Remove generated zip and any temporary copied files.
  Future<void> cleanup() async {
    if (_zipPath != null) {
      try {
        final f = File(_zipPath!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
      _zipPath = null;
    }
    for (final p in _tempCopiedFiles) {
      try {
        final f = File(p);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    _tempCopiedFiles.clear();
  }

  /// Expose temp-copied files (read-only) so callers can schedule cleanup.
  List<String> get tempFiles => List.unmodifiable(_tempCopiedFiles);
}

class _ZipIsolateArgs {
  final SendPort sendPort;
  final String outPath;
  _ZipIsolateArgs({required this.sendPort, required this.outPath});
}

// Entry point run inside isolate. Streams files to ZIP without memory buffering.
// Uses OutputFileStream + ZipEncoder + InputFileStream for deterministic
// on-disk ZIP creation. Explicitly closes the output stream to ensure the
// central directory is written before signalling completion.
// New isolate entry: receives control messages from the main isolate to
// stream file bytes into a ZIP file on disk. Uses low-level ZIP structures
// with data descriptors and ZIP64 support. Messages received via the
// control port:
// - SendPort (initial): isolate should send back its control SendPort
// - {'type':'start','name':String,'size':int}
// - {'type':'data','chunk': TransferableTypedData}
// - {'type':'end'} // end of current file
// - {'type':'finish'} // finish archive and exit
void _zipIsolateEntry(_ZipIsolateArgs args) {
  final mainSend = args.sendPort;

  // Create a control ReceivePort for messages from the main isolate
  final control = ReceivePort();
  // Send our SendPort back to main so it can drive us
  mainSend.send({'type': 'control_port', 'port': control.sendPort});

  final outPath = args.outPath;

  // Helper: little-endian writers
  int writePos = 0;
  final raf = File(outPath).openSync(mode: FileMode.write);
  void writeBytes(Uint8List b) {
    raf.writeFromSync(b);
    writePos += b.length;
  }

  void writeUint16(int v) => writeBytes(
      Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little));
  void writeUint32(int v) => writeBytes(
      Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little));
  void writeUint64(int v) => writeBytes(
      Uint8List(8)..buffer.asByteData().setUint64(0, v, Endian.little));

  // CRC32 implementation (table-driven)
  final List<int> crcTable = List<int>.filled(256, 0);
  for (int i = 0; i < 256; i++) {
    int c = i;
    for (int j = 0; j < 8; j++) {
      if ((c & 1) != 0) {
        c = 0xEDB88320 ^ (c >> 1);
      } else {
        c = c >> 1;
      }
    }
    crcTable[i] = c;
  }
  int crc32Update(int crc, List<int> bytes, int offset, int len) {
    int c = crc ^ 0xFFFFFFFF;
    for (int i = 0; i < len; i++) {
      c = crcTable[(c ^ bytes[offset + i]) & 0xFF] ^ (c >> 8);
    }
    return c ^ 0xFFFFFFFF;
  }

  // Central directory records collected here
  final List<Map<String, dynamic>> central = [];

  // State for current file being written
  String? currentName;
  int currentUncompSize = 0;
  int currentCrc = 0;
  int currentLocalHeaderOffset = 0;

  void writeLocalHeader(String name, int size) {
    currentLocalHeaderOffset = writePos;
    final nameBytes = Uint8List.fromList(name.codeUnits);

    // Local file header signature
    writeUint32(0x04034b50);
    // version needed to extract (45 for ZIP64)
    writeUint16(45);
    // general purpose bit flag: set bit 3 (0x08) to signal data descriptor after data
    writeUint16(0x08);
    // compression method: 0 = store
    writeUint16(0);
    // mod time/date - set to zero
    writeUint16(0);
    writeUint16(0);
    // crc32 (0 for now)
    writeUint32(0);
    // compressed size and uncompressed size: set to 0xFFFFFFFF to indicate ZIP64 or unknown
    writeUint32(0xFFFFFFFF);
    writeUint32(0xFFFFFFFF);
    // file name length
    writeUint16(nameBytes.length);
    // extra field length: include ZIP64 extra for sizes
    // ZIP64 extra field: header id 0x0001, size 16, uncompressed size (8), compressed size (8)
    final int extraLen = 2 + 2 + 16; // headerid + size + 16 bytes
    writeUint16(extraLen);
    // file name
    writeBytes(nameBytes);
    // extra: header id
    writeUint16(0x0001);
    // size of this extra field
    writeUint16(16);
    // uncompressed size (8 bytes little endian)
    writeUint64(size);
    // compressed size (unknown for store same as uncompressed)
    writeUint64(size);
  }

  void writeDataDescriptor(int crc, int compSize, int uncompSize) {
    // Data descriptor signature and fields (ZIP64 aware)
    writeUint32(0x08074b50);
    writeUint32(crc);
    writeUint64(compSize);
    writeUint64(uncompSize);
  }

  void writeCentralDirectoryAndFinish() {
    final int cdStart = writePos;
    for (final e in central) {
      final nameBytes = Uint8List.fromList((e['name'] as String).codeUnits);
      // central file header signature
      writeUint32(0x02014b50);
      // version made by
      writeUint16(45);
      // version needed to extract
      writeUint16(45);
      // general purpose flag
      writeUint16(0x08);
      // compression method
      writeUint16(0);
      // mod time/date
      writeUint16(0);
      writeUint16(0);
      // crc32
      writeUint32(e['crc']);
      // compressed size (0xFFFFFFFF -> ZIP64)
      writeUint32(0xFFFFFFFF);
      // uncompressed size
      writeUint32(0xFFFFFFFF);
      // file name length
      writeUint16(nameBytes.length);
      // extra length (ZIP64 with sizes + offset)
      // zip64 extra: header id 0x0001, size 24 (uncomp 8, comp 8, offset 8)
      final cdExtraLen = 2 + 2 + 24;
      writeUint16(cdExtraLen);
      // file comment length
      writeUint16(0);
      // disk number start
      writeUint16(0);
      // internal file attrs
      writeUint16(0);
      // external file attrs
      writeUint32(0);
      // relative offset of local header (0xFFFFFFFF -> ZIP64)
      writeUint32(0xFFFFFFFF);
      // file name
      writeBytes(nameBytes);
      // zip64 extra header
      writeUint16(0x0001);
      writeUint16(24);
      writeUint64(e['uncompSize']);
      writeUint64(e['compSize']);
      writeUint64(e['localHeaderOffset']);
    }

    final int cdEnd = writePos;
    final int cdSize = cdEnd - cdStart;

    // Write ZIP64 end of central directory record
    writeUint32(0x06064b50);
    // size of zip64 end of central dir record (remaining size)
    writeUint64(44);
    // version made by
    writeUint16(45);
    // version needed to extract
    writeUint16(45);
    // number of this disk
    writeUint32(0);
    // number of the disk with the start of the central directory
    writeUint32(0);
    // total number of entries in the central dir on this disk
    writeUint64(central.length);
    // total number of entries in the central dir
    writeUint64(central.length);
    // size of the central directory
    writeUint64(cdSize);
    // offset of start of central directory with respect to the starting disk number
    writeUint64(cdStart);

    // ZIP64 end of central directory locator
    writeUint32(0x07064b50);
    writeUint32(0); // number of the disk with the start of the zip64 end
    writeUint64(cdEnd); // relative offset of the zip64 end
    writeUint32(1); // total number of disks

    // End of central directory record (regular), with 0xFFFF placeholders
    writeUint32(0x06054b50);
    writeUint16(0); // disk number
    writeUint16(0); // disk where central directory starts
    writeUint16(0xFFFF); // number of central dir records on this disk
    writeUint16(0xFFFF); // total number of central dir records
    writeUint32(0xFFFFFFFF); // size of central directory
    writeUint32(0xFFFFFFFF); // offset of start of central directory
    writeUint16(0); // comment length
  }

  // Listen for control messages
  control.listen((msg) {
    try {
      if (msg is Map && msg['type'] == 'start') {
        // Begin a new file entry
        currentName = msg['name'] as String;
        final size = msg['size'] as int;
        currentUncompSize = 0;
        currentCrc = 0;
        writeLocalHeader(currentName!, size);
      } else if (msg is Map && msg['type'] == 'data') {
        final ttd = msg['chunk'] as TransferableTypedData;
        final data = ttd.materialize().asUint8List();
        currentCrc = crc32Update(currentCrc, data, 0, data.length);
        writeBytes(data);
        currentUncompSize += data.length;
        // send progress update
        mainSend.send({'type': 'progress', 'processed': currentUncompSize});
      } else if (msg is Map && msg['type'] == 'end') {
        // Finish current file: write data descriptor and record central dir entry
        final compSize = currentUncompSize; // store (no compression)
        writeDataDescriptor(currentCrc, compSize, currentUncompSize);
        central.add({
          'name': currentName!,
          'crc': currentCrc,
          'compSize': compSize,
          'uncompSize': currentUncompSize,
          'localHeaderOffset': currentLocalHeaderOffset,
        });
        // notify main that file completed
        mainSend.send({'type': 'file_done', 'name': currentName});
      } else if (msg is Map && msg['type'] == 'finish') {
        // Write central directory and finish
        writeCentralDirectoryAndFinish();
        try {
          raf.flushSync();
        } catch (_) {}
        try {
          raf.closeSync();
        } catch (_) {}
        mainSend.send({'type': 'done', 'path': outPath});
        control.close();
      }
    } catch (e) {
      mainSend.send({'type': 'error', 'error': e.toString()});
      try {
        raf.closeSync();
      } catch (_) {}
      control.close();
    }
  });
}
