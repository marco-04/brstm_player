import 'dart:io';
import 'dart:async';
import 'package:tint/tint.dart';
import 'dart:convert';

const int _MAX_TRACKS = 8;

class MPVPlayer {
  String binary = "mpv";
  String file = "";
  String pipe = "";
  double _duration = 0;
  double _timePos = 0;
  double loopPoint = 0;
  int curTrack = 0;
  int nTracks = 0;
  bool loop = false;

  int updateInterval = 0;

  bool _isRunning = false;
  // bool _isConnected = false;

  // bool _cancelLoad = false;

  bool _pingLock = false;
  bool _pingResult = false;

  Process? mpvProcess;

  Timer? _periodicAction;

  // Timer? timeoutCheck;

  // Future<void> _timeoutCheck() async {
  //   timeoutCheck = Timer.periodic(Duration(seconds: 1), (timer) {
  //     if (!_pingLock) checkIfRunning();
  //   });
  // }

  Future<void> start() async {
    if (_isRunning) return;

    try {
      mpvProcess = await Process.start(binary, ["--input-ipc-server=$pipe", "--quiet", "--idle=yes" ], runInShell: false);
    } catch(e) {
      throw Exception("[ERROR]: Cannot start mpv player instance ($e)");
    }

    _isRunning = true;
    // _isConnected = false;
    // _cancelLoad = false;

    mpvProcess!.stdout.transform(utf8.decoder).listen((data) {
      print(data);
    });
    mpvProcess!.stderr.transform(utf8.decoder).listen((data) {
      read(data.strip());
      // print(data.strip());
    });

    // _timeoutCheck();
  }

  Future<void> setTimeUpdate() async {
    if (!_isRunning) {
      return;
    }

    _periodicAction = Timer.periodic(Duration(milliseconds: updateInterval), (timer) {
      updateTimePos();
      // if (!_pingLock) checkIfRunning();
    });
  }

  Future<void> cancelPeriodicAction() async {
    if (_periodicAction != null) {
      _periodicAction!.cancel();
      _periodicAction = null;
    }
  }

  String jsonGen(String property, String requestType) => '{"result":$property,"requestType":"$requestType"}';

  // void checkIfRunning() {
  //   int timeout = 4;

  //   if (!_isRunning) {
  //     return;
  //   }

  //   while (_pingLock) sleep(Duration(milliseconds: updateInterval));

  //   if (!_isRunning) {
  //     return;
  //   }

  //   _pingLock = true;

  //   send("show-text ${jsonGen("true", "ping")}");
  //   while (!_pingResult && timeout > 0) {
  //    sleep(Duration(seconds: 1));
  //     timeout--;
  //   }

  //   if (!_pingResult) {
  //     cancelPeriodicAction();
  //     quit();
  //     _pingLock = false;
  //     throw Exception("[ERROR]: Player reply timeout");
  //   }

  //   _pingResult = false;
  //   _pingLock = false;
  // }

  Future<void> switchToTrack(int track) async {
    if (nTracks < 2) return;
    if (track < 0 || track >= _MAX_TRACKS) {
      throw Exception("[ERROR]: Invalid track number");
    }
    await send("af set lavfi=[pan=${nTracks*2}c|c0=c${track*2}|c1=c${(track*2)+1}]");
  }

  // Future<void> _periodicLoadFile(String file) async {
  //   _periodicAction = Timer.periodic(Duration(seconds: 1), (timer) {
  //     send("loadfile $file replace");
  //     updateCurrentlyPlaying();
  //   });
  // }

  Future<void> loadFile(String file) async {
    // if (!_isRunning) {
    //   return;
    // }
    // await cancelPeriodicAction();
    // _isConnected = false;
    // _duration = 0;

    // _periodicLoadFile(file);

    // while (this.file != file && !_cancelLoad) await Future.delayed(Duration(milliseconds: updateInterval));
    // if (_cancelLoad) {
    //   return;
    // }
    // await cancelPeriodicAction();
    // _isConnected = true;

    // await Future.delayed(Duration(milliseconds: updateInterval));

    await send("loadfile $file replace");

    await setTimeUpdate();

    await updateDuration();
  }

  double getPercentDuration() {
    if (!_isRunning) {
      throw Exception("[ERROR]: Player is not running");
    }
    if (_duration == 0) {
      throw Exception("[ERROR]: Invalid duration");
    }
    return _timePos/_duration;
  }

  Future<void> updateTimePos() async {
    await send("show-text ${jsonGen(r'${=time-pos}', 'playback')}");
  }

  Future<void> updateCurrentlyPlaying() async {
    await send("show-text ${jsonGen(r'"${path}"', 'current')}");
  }

  Future<void> updateDuration() async {
    await send("show-text ${jsonGen(r'${=duration}', 'duration')}");
  }

  Future<void> toggleLoop() async {
    await send("cycle-values ab-loop-count 'inf' 'no'");
  }

  Future<void> enableLoop() async {
    await send("set ab-loop-count inf");
  }

  Future<void> disableLoop() async {
    await send("set ab-loop-count 0");
  }

  Future<void> play() async {
    await send("set pause false");
  }

  Future<void> pause() async {
    await send("set pause true");
  }

  Future<void> setLoopPoint(double seconds) async {
    await send("set ab-loop-a $seconds");
    await send(r"set ab-loop-b ${=duration}");
  }
  
  Future<void> stop() async {
    // _cancelLoad = true;
    await send("stop");
  }

  Future<void> seek(double seconds) async {
    await send("seek $seconds absolute");
  }

  Future<void> quit() async {
    // _cancelLoad = true;
    await send("quit");
    _isRunning = false;
  }
  
  Future<void> send(String cmd) async {
    if (Platform.isLinux) {
      await Process.run("sh", ["-c", "echo '$cmd'" + " | socat - $pipe"]);
    } else {
      throw Exception("[ERROR]: Windows cmd is not yet implemented");
    }
    // if (!_isConnected) {
    //   print("[WARNING]: Could not verify the connection with mpv");
    // }
  }

  double getTimePos() => _timePos;

  double getDuration() => _duration;

  bool getRunningState() => _isRunning;

  Future<void> read(String ret) async {
    try {
      Function? exec;

      var readret = json.decode(ret) as Map<String, dynamic>;
      if (!readret.containsKey("result") || !readret.containsKey("requestType")) {
        return;
      }
      switch(readret["requestType"]) {
        case "playback":
          exec = (double pos) => _timePos = pos;
          break;
        case "duration":
          exec = (double duration) => _duration = duration;
          break;
        case "ping":
          exec = (bool pingResult) => _pingResult = pingResult;
        case "current":
          exec = (String current) => file = current;
        default:
          break;
      }
      
      if (exec == null) {
        return;
      }

      exec(readret["result"]);
    } on FormatException {
      // print(e);
      print(ret);
    }
  }
}

class brstmPlayer {
  int tracks = 0;
  int channels = 0;
  int sampleRate = 0;
  int duration = 0;
  double sduration = 0;
  double loopPoint = 0;
  String name = "";
  String path = "";

  int curTrack = 0;

  String? filter;

  // MPVPlayer player = MPVPlayer(verbose: true, _periodicAction: 1);

  brstmPlayer(int tracks, int channels, int sampleRate, int loopStartSample, int duration, String path) {
    // _tracks = tracks;
    // _channels = channels;
    // _sampleRate = sampleRate;
    // _duration = duration;
    // _sduration = getSeconds(duration);
    // _path = path.substring(0, path.lastIndexOf("/"));
    // _name = path.substring(path.lastIndexOf("/")+1, path.length);
  }

}
