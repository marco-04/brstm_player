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
  Uint8List? brstmBuffer;
  ByteData? brstmContents;

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
      curPos = pos;
    }
  }

  String? getString(int len) {
    if (isOpen()) {
      Uint8List list = Uint8List.sublistView(brstmContents as TypedData, curPos, curPos+len);
      return String.fromCharCodes(list);
    }
    return null;
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
    if (!isOpen()) {
      brstmBuffer = brstmFile!.readAsBytesSync();
      brstmContents = ByteData.view(brstmBuffer!.buffer);

      setPos(0);
      if (getString(4) == "RSTM") {
        isBRSTM = true;
      }
    }
  }

  void read() {
    if (isOpen()) {
      setPos(brstmContents!.getUint32(INITIAL_POSITION));
      if (getString(4) == "HEAD") {
        print("OK");
      }
    }
  }
}
