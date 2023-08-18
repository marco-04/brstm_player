import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

class BRSTM {
  bool _isBrstmFile = false;

  //bool BOM = false;
  int _head = 0;
  // int _headSize = 0;

  // int adpc = 0;
  // int adpcSize = 0;

  // int data = 0;
  // int dataSize = 0;

  int _tracks = 0;
  int _channels = 0;
  bool _loop = false;
  int _loopStartSample = 0;
  int _totalSamples = 0;

  static const int _INITIAL_POSITION = 0x10;

  int _curPos = 0;

  File? _brstmFile;
  Uint8List? _brstmBuffer;
  ByteData? _contentsPointer;
  //ByteData? _brstmContents;

  /// Create an BRSTM object.
  ///
  ///  If `path` does not exist an Exception is raised.
  BRSTM(String path) {
    if (!File(path).existsSync()) {
      throw Exception("File $path does not exist");
    }
    _brstmFile = File(path);
  }

  bool isOpen() => _contentsPointer != null;
  bool isBrstm() => _isBrstmFile;

  void setPos(int pos) => _curPos = pos;
  int getPos() => _curPos;

  /// Reads `len` bytes starting at current position (included).
  String? getString(int len) {
    if (!isOpen())
      return null;

    Uint8List list = Uint8List.sublistView(_contentsPointer as TypedData, _curPos, _curPos+len);
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
  
  void open() {
    if (isOpen())
      return;

    _brstmBuffer = _brstmFile!.readAsBytesSync();
    _contentsPointer = ByteData.view(_brstmBuffer!.buffer);

    setPos(0);
    if (getString(4) == "RSTM") {
      _isBrstmFile = true;
    }
  }

  void read() {
    if (!isOpen())
      return;
      
    setPos(_curPos = _contentsPointer!.getUint32(_INITIAL_POSITION));
    if (getString(4) == "HEAD") {
      _head = _curPos;
      print("OK");
      print(_head.toRadixString(16));
    }
  }
}
