import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

class BRSTM {
  //bool _BOM = false;

  static const int _INITIAL_OFFSET = 0x14;
  static const int _HEADER_SIZE = 0x40;

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

  int _tracks = 0;
  int _channels = 0;
  bool _loop = false;
  int _loopStartSample = 0;
  int _totalSamples = 0;

  int _curPos = 0;

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

  void setPos(int pos) => _curPos = pos;
  int getPos() => _curPos;

  /// Reads `len` bytes starting at current position (included).
  String? getString(ByteData buf, int len) {
    if (!isOpen())
      return null;

    Uint8List list = Uint8List.sublistView(buf as TypedData, _curPos, _curPos+len);
    return String.fromCharCodes(list);
  }

  // int? readData({int offset = 0}) {
  //   if (isOpen()) {
  //     if (offset < 0) {
  //       return null;
  //     }

  //     if (offset > 0) {
  //       brstmContents!.setPositionSync(curPos+offset);
  //     }

  //     return brstmContents!.readByteSync();
  //   }
  //   return null;
  // }
  
  void openSync() {
    if (isOpen())
      return;

    _brstmBuffer = _brstmFile!.openSync();
    _fileHeader = ByteData.view(_brstmBuffer!.readSync(_HEADER_SIZE).buffer);

    //setPos(0);
    if (getString(_fileHeader as ByteData, 4) == "RSTM") {
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
    if (getString(_contentsPointer as ByteData, 4) == "HEAD") {
      //_head = _curPos;
      print("OK");
      print(_head.toRadixString(16));
    }
  }
}
