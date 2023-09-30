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
///Previosly known as `_TOTAL_SAMPLES_OFFSET`
const int _LOOP_END_OFFSET = 0x0C;

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

  //bool verbose = false;
  ///Contains 3 offsets values, one for each `BrstmTables`. These offsets are used to find the location of the 3 tables.
  List<int>? _tableOffsets;

  int _tracks = 0;
  int _channels = 0;
  int _sampleRate = 0;
  int _loop = 0;
  int _loopStartSample = 0;
  ///Previosly known as `_totalSamples`
  int _loopEndSample = 0;

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
      throw Exception("[FAILED]: File $path does not exist");
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
        ' loopEndSample: $_loopEndSample'
        '}';
  }

  bool isOpen() => _brstmBuffer != null && _brstmBuffer?.positionSync() != null;
  bool isBrstm() => _isBrstmFile;
  String? getFilePath() => _brstmFile?.path;
  int? getFileSize() => _brstmFile?.lengthSync();
  int? getLoopStart() => _loopStartSample;
  int? getLoopEnd() => _loopEndSample;
  int? getSampleRate() => _sampleRate;
  int? getChannels() => _channels;

  double? getDuration() => _loopEndSample / _sampleRate;

  ///Sets `_loopStartSample` variable and updates `_headContents`
  int setLoopPointSampleStart(int loopPoint) {
    _loopStartSample = loopPoint;
    writeHeadToFileSync();

    return loopPoint;
  }

  ///Sets `_loopEndSample` variable and updates `_headContents`
  int setLoopPointSampleEnd(int loopPoint) {
    _loopEndSample = loopPoint;
    writeHeadToFileSync();
    return loopPoint;
  }

  ///Copies `_tracks`,`_channels`,`_sampleRate`,`_loop`,`_loopStartSample`,`_loopEndSample` in `_headContents`
  void writeHeadToFileSync() {
    if (!isOpen()) {
      throw Exception('[FAILED]: File is not open');
    }
    if (!_isBrstmFile) {
      throw Exception(
          '[FAILED]: File does not appear to be a brstm. Did you read the header first?');
    }

    RandomAccessFile raf = _brstmFile!.openSync(mode: FileMode.append);

    // _headContents!.setUint8(
    //     _HEAD_REFS_OFFSET +
    //         _tableOffsets![BrstmTables.streamDataTable.index] +
    //         _LOOP_FLAG_OFFSET,
    //     _loop);

    raf.setPositionSync(_HEADER_SIZE +
        _HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _LOOP_FLAG_OFFSET);

    raf.writeByteSync(_loop);
    // _headContents!.setUint8(
    //     _HEAD_REFS_OFFSET +
    //         _tableOffsets![BrstmTables.streamDataTable.index] +
    //         _N_CHANNEL_OFFSET,
    //     _channels);
    raf.setPositionSync(_HEADER_SIZE +
        _HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _N_CHANNEL_OFFSET);
    raf.writeByteSync(_channels);
    // setUint24(
    //     _headContents as ByteData,
    //     _HEAD_REFS_OFFSET +
    //         _tableOffsets![BrstmTables.streamDataTable.index] +
    //         _SAMPLE_RATE_OFFSET,
    //     _sampleRate);

    raf.setPositionSync(_HEADER_SIZE +
        _HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _SAMPLE_RATE_OFFSET);
    raf.writeByteSync((_sampleRate >> 16) & 0xFF); // Write the first byte
    raf.writeByteSync((_sampleRate >> 8) & 0xFF); // Write the second byte
    raf.writeByteSync(_sampleRate & 0xFF); // Write the third byte

    // _headContents!.setUint32(
    //     _HEAD_REFS_OFFSET +
    //         _tableOffsets![BrstmTables.streamDataTable.index] +
    //         _LOOP_START_OFFSET,
    //     _loopStartSample);
    raf.setPositionSync(_HEADER_SIZE +
        _HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _LOOP_START_OFFSET);
    raf.writeByteSync((_loopStartSample >> 24) & 0xFF); // Write the first byte
    raf.writeByteSync((_loopStartSample >> 16) & 0xFF); // Write the second byte
    raf.writeByteSync((_loopStartSample >> 8) & 0xFF); // Write the third byte
    raf.writeByteSync(_loopStartSample & 0xFF);

    // _headContents!.setUint32(
    //     _HEAD_REFS_OFFSET +
    //         _tableOffsets![BrstmTables.streamDataTable.index] +
    //         _LOOP_END_OFFSET,
    //     _loopEndSample);
    raf.setPositionSync(_HEADER_SIZE +
        _HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _LOOP_END_OFFSET);
    print(_HEADER_SIZE +
        _HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _LOOP_END_OFFSET);

    raf.writeByteSync((_loopEndSample >> 24) & 0xFF); // Write the first byte
    raf.writeByteSync((_loopEndSample >> 16) & 0xFF); // Write the second byte
    raf.writeByteSync((_loopEndSample >> 8) & 0xFF); // Write the third byte
    raf.writeByteSync(_loopEndSample & 0xFF);

    // _headContents!.setUint32(
    //     0x14 + _tableOffsets![BrstmTables.streamDataTable.index],
    //     _totalSamples);

    // _headContents!.setUint8(
    //     _HEAD_REFS_OFFSET + _tableOffsets![BrstmTables.trackTable.index],
    //     _tracks);
    raf.setPositionSync(_HEADER_SIZE +
        _HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.trackTable.index]);

    raf.writeByteSync(_tracks);

    // print(_HEAD_REFS_OFFSET + _tableOffsets![BrstmTables.trackTable.index]);
    // print(_tracks);
    raf.flushSync();
    raf.closeSync();
    readHeadSync();
  }

  /// Reads 4 bytes "magic strings" starting at current position (included).
  String? readMagic(ByteData buf) {
    if (!isOpen()) return null;
    Uint8List list = Uint8List.sublistView(buf, 0, 4);
    return String.fromCharCodes(list);
  }

  int _readUint24(ByteData buf, int offset) {
    // Get an Uint32
    int tmp = buf.getUint32(offset);
    // Shift tmp by one byte (8 bits) to the right to get rid of the rightmost byte
    tmp >>= 8;
    return tmp;
  }

  void setUint24(ByteData byteData, int byteOffset, int value24) {
    // Ensure that the value is within the 24-bit range
    if (value24 < 0 || value24 > 0xFFFFFF) {
      throw ArgumentError(
          'The value must be between 0 and 0xFFFFFF (24 bits).');
    }

    // Extract the three separate bytes from the 24-bit value
    int byte1 = (value24 >> 16) & 0xFF;
    int byte2 = (value24 >> 8) & 0xFF;
    int byte3 = value24 & 0xFF;

    // Use the existing methods to write the three bytes
    byteData.setUint8(byteOffset, byte1);
    byteData.setUint8(byteOffset + 1, byte2);
    byteData.setUint8(byteOffset + 2, byte3);
  }

  ///Opens the files and sets `_brstmBuffer` to position 0.
  void open() {
    _brstmBuffer = _brstmFile!.openSync();
  }

  ///Closes the files and sets `_brstmBuffer` to null;
  void close() {
    _brstmBuffer?.closeSync();
    _brstmBuffer = null;
  }

  //-----------------------------------------
  // Synchronous functions

  ///Synchronously reads the HEADER partition of the file and updates the `_headerContents` variable with the content.
  ///
  ///This also updates `_isBrstmFile`
  void readHeaderSync() {
    if (!isOpen()) {
      throw Exception('[FAILED]: File is not open');
    }

    String? tmpMagic;

    _headerContents =
        ByteData.view(_brstmBuffer!.readSync(_HEADER_SIZE).buffer);

    if (!(_isBrstmFile =
        ((tmpMagic = readMagic(_headerContents as ByteData)) == "RSTM"))) {
      throw Exception(
          '[FAILED]: File does not appear to be a brstm. Header magic string check failed ($tmpMagic != RSTM)');
    }
  }

  ///Synchronously reads the HEAD partition of the file. The Header must be read first with `readHeaderSync()`;
  ///
  ///This updates the `_headContents`, `_tracks`,`_channels`,`_sampleRate`,`_loop`,`_loopStartSample`,`_totalSamples`.
  void readHeadSync() {
    if (!isOpen()) {
      throw Exception("[FAILED]: File does not appear to be open");
    }

    if (!isBrstm()) {
      throw Exception("[FAILED]: File does not appear to be a brstm");
    }

    String? tmpMagic;

    _headSize = _headerContents!.getUint32(_INITIAL_OFFSET);
    _brstmBuffer!.setPositionSync(_HEADER_SIZE);
    _headContents = ByteData.view(_brstmBuffer!.readSync(_headSize).buffer);

    if (!(_isBrstmFile =
        ((tmpMagic = readMagic(_headContents as ByteData)) == "HEAD"))) {
      throw Exception(
          '[FAILED]: File does not appear to be a brstm. HEAD magic string check failed ($tmpMagic != HEAD)');
    }

    var (
      tracks,
      channels,
      sampleRate,
      loop,
      loopStartSample,
      loopEndSample,
    ) = _parseHeadSync();
    _tracks = tracks;
    _channels = channels;
    _sampleRate = sampleRate;
    _loop = loop;
    _loopStartSample = loopStartSample;
    _loopEndSample = loopEndSample;
  }

  ///Updates the contents of `_tableOffsets`. The HEAD must be read first.
  bool _readTablesSync() {
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

  ///Parses `_headContents`.
  ///
  ///Returns (tracks,channels,sampleRate,loop,loopStartSample,loopEndSample)
  (int, int, int, int, int, int) _parseHeadSync() {
    if (!isOpen()) {
      throw Exception(
          '[FAILED]: Cannot the read file. Please call open() first.');
    }

    if (!_readTablesSync()) {
      throw Exception("[FAILED]: Could not find DataRefs");
    }

    int loop = _headContents!.getUint8(_HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _LOOP_FLAG_OFFSET);
    int channels = _headContents!.getUint8(_HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _N_CHANNEL_OFFSET);
    int sampleRate = _readUint24(_headContents as ByteData,
        _HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _SAMPLE_RATE_OFFSET);
    int loopStartSample = _headContents!.getUint32(_HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _LOOP_START_OFFSET);
    int loopEndSample = _headContents!.getUint32(_HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _LOOP_END_OFFSET);
    int tracks = _headContents!.getUint8(
        _HEAD_REFS_OFFSET + _tableOffsets![BrstmTables.trackTable.index]);

    return (
      tracks,
      channels,
      sampleRate,
      loop,
      loopStartSample,
      loopEndSample
    );
  }

  ///Synchronously reads the files
  void readSync() {
    readHeaderSync();
    readHeadSync();
  }

  //-----------------------------------------
  // Asynchronous functions

  ///Asynchronously reads the HEADER partition of the file and updates the `_headerContents` variable with the content.
  ///
  ///This also updates `_isBrstmFile`
  Future<void> readHeader() async {
    if (!isOpen()) {
      throw Exception('[FAILED]: File is not open');
    }

    String? tmpMagic;

    _headerContents =
        ByteData.view(_brstmBuffer!.readSync(_HEADER_SIZE).buffer);

    if (!(_isBrstmFile =
        ((tmpMagic = readMagic(_headerContents as ByteData)) == "RSTM"))) {
      throw Exception(
          '[FAILED]: File does not appear to be a brstm. Header magic string check failed ($tmpMagic != RSTM)');
    }
  }

  ///Asynchronously reads the HEAD partition of the file. The Header must be read first
  ///
  ///This updates the `_headContents`, `_tracks`,`_channels`,`_sampleRate`,`_loop`,`_loopStartSample`,`_loopEndSample`.
  Future<void> readHead() async {
    if (!isOpen()) {
      throw Exception("[FAILED]: File does not appear to be open");
    }

    if (_headerContents == null) {
      throw Exception("[FAILED]: Invalid Header");
    }

    if (!isBrstm()) {
      throw Exception("[FAILED]: File does not appear to be a brstm");
    }

    String? tmpMagic;

    _headSize = _headerContents!.getUint32(_INITIAL_OFFSET);
    await _brstmBuffer!.setPosition(_HEADER_SIZE);
    _headContents = ByteData.view(_brstmBuffer!.readSync(_headSize).buffer);

    if (!(_isBrstmFile =
        ((tmpMagic = readMagic(_headContents as ByteData)) == "HEAD"))) {
      throw Exception(
          '[FAILED]: File does not appear to be a brstm. HEAD magic string check failed ($tmpMagic != HEAD)');
    }

    var (
      tracks,
      channels,
      sampleRate,
      loop,
      loopStartSample,
      loopEndSample
    ) = await _parseHead();
    _tracks = tracks;
    _channels = channels;
    _sampleRate = sampleRate;
    _loop = loop;
    _loopStartSample = loopStartSample;
    _loopEndSample = loopEndSample;
  }

  /// Updates the contents of `_tableOffsets`
  Future<bool> _readTables() async {
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

  ///Asynchronously parses `_headContents`.
  ///
  ///Returns (tracks,channels,sampleRate,loop,loopStartSample,loopEndSample)
  Future<(int, int, int, int, int, int)> _parseHead() async {
    if (!isOpen()) {
      throw Exception(
          '[FAILED]: Cannot the read file. Please call open() first.');
    }

    if (!await _readTables()) {
      throw Exception("[FAILED]: Could not find DataRefs");
    }

    int loop = _headContents!.getUint8(_HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _LOOP_FLAG_OFFSET);
    int channels = _headContents!.getUint8(_HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _N_CHANNEL_OFFSET);
    int sampleRate = _readUint24(_headContents as ByteData,
        _HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _SAMPLE_RATE_OFFSET);
    int loopStartSample = _headContents!.getUint32(_HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _LOOP_START_OFFSET);
    int loopEndSample = _headContents!.getUint32(_HEAD_REFS_OFFSET +
        _tableOffsets![BrstmTables.streamDataTable.index] +
        _LOOP_END_OFFSET);
    int tracks = _headContents!.getUint8(
        _HEAD_REFS_OFFSET + _tableOffsets![BrstmTables.trackTable.index]);

    return (
      tracks,
      channels,
      sampleRate,
      loop,
      loopStartSample,
      loopEndSample
    );
  }

  ///Asynchronously reads the files
  Future<void> read() async {
    await readHeader();
    await readHead();
  }

}
