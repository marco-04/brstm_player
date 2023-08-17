import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

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

  static const int INITIAL_POSITION = 0x10;

  int curPos = 0;

  File? brstmFile;
  RandomAccessFile? brstmContents;

  BRSTM(String path) {
    if(!File(path).existsSync()) {
      throw Exception("File $path does not exist");
    }
    brstmFile = File(path);
  }

  bool isOpen() {
    return brstmContents != null;
  }

  void setPos(int pos) {
    if (isOpen()) {
      brstmContents!.setPositionSync(pos);
      updatePos();
    }
  }

  String? getString(int len) {
    String ret = "";
    if (isOpen()) {
      for (int i = 0; i < len; i++) {
        ret += String.fromCharCode(brstmContents!.readByteSync());
      }
      updatePos();
      return ret;
    }
    return null;
  }

  void updatePos() {
    curPos = brstmContents!.positionSync();
  }

  int? readData({int offset = 0}) {
    if (isOpen()) {
      if (offset < 0) {
        return null;
      }

      if (offset > 0) {
        brstmContents!.setPositionSync(curPos+offset);
      }

      return brstmContents!.readByteSync();
    }
    return null;
  }
  
  void open() {
    brstmContents = brstmFile!.openSync();

    setPos(0);
    if (getString(4) == "RSTM") {
      isBRSTM = true;
    }
  }
}
