// ignore_for_file: constant_identifier_names

import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

enum BrstmTables { streamDataTable, trackTable, channelTable }

const int _INITIAL_OFFSET = 0x14;
const int _HEADER_SIZE = 0x40;

const int _HEAD_REFS_OFFSET = 0x08;

const int _REFERENCE_MASK = 0x01000000;
const int _REFERENCE_SIZE = 8;
const int _REFERENCE_VALUE = 4;

const int _LOOP_FLAG_OFFSET = 0x01;
const int _N_CHANNEL_OFFSET = 0x02;
const int _SAMPLE_RATE_OFFSET = 0x03;
const int _LOOP_START_OFFSET = 0x08;
const int _TOTAL_SAMPLES_OFFSET = 0x0C;

class BRSTM {
  //bool _BOM = false;

  /// Offset of the HEAD section
  ///
  /// The file header has always the size of 0x40 and is always adjacent to HEAD
  //int _head = _HEADER_SIZE;

  /// Size of the HEAD section
  ///
  /// Found at offset 0x14 in the file header
  int _headSize = 0;

  // int _adpc = 0;
  // int _adpcSize = 0;

  // int _data = 0;
  // int _dataSize = 0;

  //int logLevel = 0;
  ///Contains 3 offsets values, one for each `BrstmTables`. These offsets are used to find the location of the 3 tables.
  List<int>? _tableOffsets;

  int _tracks = 0;
  int _channels = 0;
  int _sampleRate = 0;
  int _loop = 0;
  int _loopStartSample = 0;
  int _totalSamples = 0;

  bool _isBrstmFile = false;

  File? _brstmFile;
  RandomAccessFile? _brstmBuffer;
  ByteData? _headerContents;
  ByteData? _headContents;

  /// Create an BRSTM object.
  ///
  /// If `path` does not exist an Exception is raised.
  BRSTM(String path) {
    if (!File(path).existsSync()) {
      throw Exception("File $path does not exist");
    }
    _brstmFile = File(path);
  }

  @override
  String toString() {
    return 'file: ${_brstmFile?.path}\n'
        'isBrstmFile: ${isBrstm()}\n'
        'isOpen: ${isOpen()}\n'
        'HEAD {'
        ' tracks: $_tracks,'
        ' channels: $_channels,'
        ' sampleRate: $_sampleRate,'
        ' loop: $_loop,'
        ' loopStartSample: $_loopStartSample,'
        ' totalSamples: $_totalSamples'
        '}';
  }

  bool isOpen() => _brstmBuffer != null && _brstmBuffer?.positionSync() != null;
  bool isBrstm() => _isBrstmFile;

  /// Reads `len` bytes starting at current position (included).
  String? readMagic(ByteData buf, int len) {
    if (!isOpen()) return null;
    Uint8List list = Uint8List.sublistView(buf, 0, len);
    return String.fromCharCodes(list);
  }

  ///Updates the contents of `_tableOffsets`. The HEAD must be read first.
  bool _readTables() {
    for (int i = 0; i < 3; i++) {
      if (_REFERENCE_MASK !=
          _headContents!.getUint32(_HEAD_REFS_OFFSET + (i * _REFERENCE_SIZE))) {
        return false;
      }
    }

    _tableOffsets = [0, 0, 0];

    for (int i = 0; i < 3; i++) {
      _tableOffsets![i] = _headContents!.getUint32(
          _HEAD_REFS_OFFSET + (i * _REFERENCE_SIZE) + _REFERENCE_VALUE);
    }

    // print("_readTablesSync()");
    // print(_tableOffsets![BrstmTables.streamDataTable.index].toRadixString(16));
    // print(_tableOffsets![BrstmTables.trackTable.index].toRadixString(16));
    // print(_tableOffsets![BrstmTables.channelTable.index].toRadixString(16));

    return true;
  }

  ///Synchronously opens the files and sets `_brstmBuffer` to position 0.
  ///
  ///
  void openSync() {
    _brstmBuffer = _brstmFile!.openSync();
  }

  ///Synchronously closes the files and sets `_brstmBuffer` to null;
  void closeSync() {
    _brstmBuffer?.closeSync();
    _brstmBuffer = null;
  }

  ///Synchronously reads the HEADER partition of the file and updates the `_headerContents` variable with the content.
  ///
  ///This also updates `_isBrstmFile`
  void readHeaderSync() {
    if (!isOpen()) {
      throw Exception('Cannot the read file. Please call openSync() first.');
    }

    _brstmBuffer = _brstmFile!.openSync();
    _headerContents =
        ByteData.view(_brstmBuffer!.readSync(_HEADER_SIZE).buffer);

    if (readMagic(_headerContents as ByteData, 4) == "RSTM") {
      _isBrstmFile = true;
    } else {
      return;
    }
  }

  ///Synchronously reads the HEAD partition of the file. The Header must be read first with `readHeaderSync()`;
  ///
  ///This updates the `_headContents`, `_tracks`,`_channels`,`_sampleRate`,`_loop`,`_loopStartSample`,`_totalSamples`.
  readHeadSync() {
    _headSize = _headerContents!.getUint32(_INITIAL_OFFSET);
    _brstmBuffer!.setPositionSync(_HEADER_SIZE);
    _headContents = ByteData.view(_brstmBuffer!.readSync(_headSize).buffer);
    var (tracks, channels, sampleRate, loop, loopStartSample, totalSamples) =
        _parseHead();
    _tracks = tracks;
    _channels = channels;
    _sampleRate = sampleRate;
    _loop = loop;
    _loopStartSample = loopStartSample;
    _totalSamples = totalSamples;
  }

  ///Parses `_headContents`.
  ///
  ///Returns (tracks,channels,sampleRate,loop,loopStartSample,totalSamples)
  (int, int, int, int, int, int) _parseHead() {
    if (!isOpen()) {
      throw Exception('Cannot the read file. Please call open() first.');
    }
    //setPos(_curPos = _contentsPointer!.getUint32(_INITIAL_OFFSET));
    if (readMagic(_headContents as ByteData, 4) != "HEAD") {
      throw Exception('Invalid HEAD. Please. read it First readHeadSync()');
    }

    if (!_readTables()) {
      stderr.write("[FAILED]: Could not find DataRefs");
      throw Exception();
    }

    int loop = _headContents!.getUint8(_HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _LOOP_FLAG_OFFSET);
    int channels = _headContents!.getUint8(_HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _N_CHANNEL_OFFSET);
    int sampleRate = _headContents!.getUint16(_HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _SAMPLE_RATE_OFFSET);
    sampleRate <<= 8;
    sampleRate += _headContents!.getUint8(_HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _SAMPLE_RATE_OFFSET +
        2);
    int loopStartSample = _headContents!.getUint32(_HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _LOOP_START_OFFSET);
    int totalSamples = _headContents!.getUint32(_HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _TOTAL_SAMPLES_OFFSET);
    int tracks = _headContents!.getUint8(
        _HEAD_REFS_OFFSET + _tableOffsets![BrstmTables.trackTable.index]);

    return (tracks, channels, sampleRate, loop, loopStartSample, totalSamples);
  }
}
