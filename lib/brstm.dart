import 'dart:core';
import 'dart:io';

//import 'dart:typed_data';

class BRSTM {
  bool isBRSTM = false;

  //bool BOM = false;
  int head = 0;
  int headSize = 0;

  // int adpc = 0;
  // int adpcSize = 0;

  // int data = 0;
  // int dataSize = 0;

  int tracks = 0;
  int channels = 0;
  bool loop = false;
  int loopStartSample = 0;
  int totalSamples = 0;
  int fileSize = -1;
  static const int initialPosition = 0x10;

  File? brstmFile;
  RandomAccessFile? _contentsPointer;

  /// Create an BRSTM object.
  ///
  ///  If `path` does not exist an Exception is raised.
  BRSTM(String path) {
    if (!File(path).existsSync()) {
      throw Exception("File $path does not exist");
    }
    brstmFile = File(path);
    fileSize = brstmFile!.lengthSync();
    _contentsPointer = null;
  }

  void open() {
    _contentsPointer = brstmFile!.openSync();
    setPos(0);
    isBRSTM = getString(4) == "RSTM";
  }

  void close() {
    if (!isOpen()) {
      return;
    }
    _contentsPointer!.closeSync();
  }

  bool isOpen() {
    return _contentsPointer != null;
  }

  ///Sets pointer position to `pos`
  void setPos(int pos) {
    if (isOpen()) {
      _contentsPointer!.setPositionSync(pos);
    }
  }

  /// Reads `len` bytes starting at current position (included).
  String? getString(int len) {
    if (!isOpen()) {
      return null;
    }
    String ret = "";
    for (int i = 0; i < len; i++) {
      ret += String.fromCharCode(_contentsPointer!.readByteSync());
    }
    return ret;
  }
}
