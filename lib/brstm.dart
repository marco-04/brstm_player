import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

enum _tables { streamDataTable, trackTable, channelTable }

class BRSTM {
  //bool _BOM = false;

  static const int _INITIAL_OFFSET = 0x14;
  static const int _HEADER_SIZE = 0x40;

  static const int _HEAD_REFS_OFFSET = 0x08;

  static const int _REFERENCE_MASK = 0x01000000;
  static const int _REFERENCE_SIZE = 8;
  static const int _REFERENCE_VALUE = 4;

  static const int _LOOP_FLAG_OFFSET = 0x01;
  static const int _N_CHANNEL_OFFSET = 0x02;
  static const int _SAMPLE_RATE_OFFSET = 0x03;
  static const int _LOOP_START_OFFSET = 0x08;
  static const int _TOTAL_SAMPLES_OFFSET = 0x0C;

  /// Offset of the HEAD section
  ///
  /// The file header has always the size of 0x40 and is always adjacent to HEAD
  int _head = _HEADER_SIZE;
  /// Size of the HEAD section
  ///
  /// Found at offset 0x14 in the file header
  int _headSize = 0;

  // int _adpc = 0;
  // int _adpcSize = 0;

  // int _data = 0;
  // int _dataSize = 0;

  //int logLevel = 0;

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
  ByteData? _fileHeader;
  ByteData? _contentsPointer;

  /// Create an BRSTM object.
  ///
  ///  If `path` does not exist an Exception is raised.
  BRSTM(String path) {
    if (!File(path).existsSync()) {
      throw Exception("File $path does not exist");
    }
    _brstmFile = File(path);
  }

  bool isOpen() => _fileHeader != null;
  bool isBrstm() => _isBrstmFile;

  /// Reads `len` bytes starting at current position (included).
  String? readMagic(ByteData buf, int len) {
    if (!isOpen())
      return null;

    Uint8List list = Uint8List.sublistView(buf as TypedData, 0, len);
    return String.fromCharCodes(list);
  }

  bool _readTables() {
    for (int i = 0; i < 3; i++) 
      if (_REFERENCE_MASK != _contentsPointer!.getUint32(_HEAD_REFS_OFFSET+(i*_REFERENCE_SIZE)))
        return false;

    _tableOffsets = [0, 0, 0];

    for (int i = 0; i < 3; i++)
      _tableOffsets![i] = _contentsPointer!.getUint32(_HEAD_REFS_OFFSET+(i*_REFERENCE_SIZE)+_REFERENCE_VALUE);

    print("_readTablesSync()");
    print(_tableOffsets![_tables.streamDataTable.index].toRadixString(16));
    print(_tableOffsets![_tables.trackTable.index].toRadixString(16));
    print(_tableOffsets![_tables.channelTable.index].toRadixString(16));

    return true;
  }
  
  void openSync() {
    if (isOpen())
      return;

    _brstmBuffer = _brstmFile!.openSync();
    _fileHeader = ByteData.view(_brstmBuffer!.readSync(_HEADER_SIZE).buffer);

    //setPos(0);
    if (readMagic(_fileHeader as ByteData, 4) == "RSTM") {
      _isBrstmFile = true;
    } else {
      return;
    }

    _headSize = _fileHeader!.getUint32(_INITIAL_OFFSET);
    _brstmBuffer!.setPositionSync(_HEADER_SIZE);
    _contentsPointer = ByteData.view(_brstmBuffer!.readSync(_headSize).buffer);
  }

  void readSync() {
    if (!isOpen())
      return;
    //setPos(_curPos = _contentsPointer!.getUint32(_INITIAL_OFFSET));
    if (readMagic(_contentsPointer as ByteData, 4) != "HEAD")
      return;

    if (!_readTables()) {
      stderr.write("[FAILED]: Could not find DataRefs");
      return;
    }

    _loop = _contentsPointer!.getUint8(_HEAD_REFS_OFFSET+_tableOffsets![_tables.streamDataTable.index]+_LOOP_FLAG_OFFSET);
    _channels = _contentsPointer!.getUint8(_HEAD_REFS_OFFSET+_tableOffsets![_tables.streamDataTable.index]+_N_CHANNEL_OFFSET);
    _sampleRate = _contentsPointer!.getUint16(_HEAD_REFS_OFFSET+_tableOffsets![_tables.streamDataTable.index]+_SAMPLE_RATE_OFFSET);
    _sampleRate <<= 8;
    _sampleRate += _contentsPointer!.getUint8(_HEAD_REFS_OFFSET+_tableOffsets![_tables.streamDataTable.index]+_SAMPLE_RATE_OFFSET+2);
    _loopStartSample = _contentsPointer!.getUint32(_HEAD_REFS_OFFSET+_tableOffsets![_tables.streamDataTable.index]+_LOOP_START_OFFSET);
    _totalSamples = _contentsPointer!.getUint32(_HEAD_REFS_OFFSET+_tableOffsets![_tables.streamDataTable.index]+_TOTAL_SAMPLES_OFFSET);
    _tracks = _contentsPointer!.getUint8(_HEAD_REFS_OFFSET+_tableOffsets![_tables.trackTable.index]);

    print(
      """readSync():
      \tTracks = $_tracks
      \tChannels = $_channels
      \tSample Rate = $_sampleRate
      \tLoop = $_loop
      \tLoop start sample = $_loopStartSample
      \tTotal samples = $_totalSamples
      """
    );
  }
}
