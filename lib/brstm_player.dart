import 'dart:io';
import 'dart:async';
import 'package:tint/tint.dart';
import 'dart:convert';

const int _MAX_TRACKS = 8;

class MPVPlayer {
  String binary = "";
  String file = "";
  String pipe = "";
  double duration = 0;
  double timePos = 0;
  double loopPoint = 0;
  int curTrack = 0;
  int nTracks = 0;
  bool loop = false;

  int updateInterval = 0;

  bool isRunning = false;

  bool _pingLock = false;
  bool _pingResult = false;

  Process? mpvProcess;

  Timer? timeUpdate;
  
  Future<void> start() async {
    if (isRunning) return;

    try {
      mpvProcess = await Process.start(binary, [file, "--input-ipc-server=$pipe", "--quiet", "--idle=yes" ], runInShell: false);
    } catch(e) {
      throw Exception("[FAILED]: Cannot start mpv player instance ($e)");
    }

    isRunning = true;

    mpvProcess!.stdout.transform(utf8.decoder).listen((data) {
      print(data);
    });
    mpvProcess!.stderr.transform(utf8.decoder).listen((data) {
      read(data.strip());
      // print(data.strip());
    });

    await setTimeUpdate();

    await updateDuration();
  }

  Future<void> setTimeUpdate() async {
    if (!isRunning) {
      return;
    }

    timeUpdate = Timer.periodic(Duration(milliseconds: updateInterval), (timer) {
      updateTimePos();
      if (!_pingLock) checkIfRunning();
    });
  }

  Future<void> cancelTimeUpdate() async {
    if (timeUpdate != null) {
      timeUpdate!.cancel();
      timeUpdate = null;
    }
  }

  String jsonGen(String property, String requestType) => '{"result":$property,"requestType":"$requestType"}';

  Future<void> checkIfRunning() async {
    if (!isRunning) {
      return;
    }

    while (_pingLock);

    if (!isRunning) {
      return;
    }

    _pingLock = true;

    await send("show-text ${jsonGen("true", "ping")}");
    await Future.delayed(Duration(milliseconds: 2*updateInterval));

    if (!_pingResult) {
      cancelTimeUpdate();
      quit();
      _pingLock = false;
      throw Exception("[FAILED]: Player reply timeout");
    }

    _pingResult = false;
    _pingLock = false;
  }

  Future<void> switchToTrack(int track) async {
    if (nTracks < 2) return;
    if (track < 0 || track >= _MAX_TRACKS) {
      throw Exception("[FAILED]: Invalid track number");
    }
    await send("af set lavfi=[pan=${nTracks*2}c|c0=c${track*2}|c1=c${(track*2)+1}]");
  }

  Future<void> loadFile(String file) async {
    await send("loadfile $file replace");
  }

  double getPercentDuration() {
    if (!isRunning) {
      throw Exception("[FAILED]: Player is not running");
    }
    if (duration == 0) {
      throw Exception("[FAILED]: Invalid duration");
    }
    return timePos/duration;
  }

  Future<void> updateTimePos() async {
    // await send(r'show-text {"result":${time-pos},"requestType":"playback"}');
    await send("show-text ${jsonGen(r'${=time-pos}', 'playback')}");
  }

  Future<void> updateDuration() async {
    // await send(r'show-text {"result":${time-pos},"requestType":"playback"}');
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
    await send("play");
  }

  Future<void> pause() async {
    await send("pause");
  }

  Future<void> setLoopPoint(double seconds) async {
    await send("set ab-loop-a $seconds");
    await send(r"set ab-loop-b ${=duration}");
  }
  
  Future<void> stop() async {
    await send("stop");
  }

  Future<void> quit() async {
    await send("quit");
    isRunning = false;
  }
  
  Future<void> send(String cmd) async {
    await Process.run("sh", ["-c", "echo '$cmd'" + " | socat - $pipe"]);
  }

  double getTimePos() => timePos;

  Future<void> read(String ret) async {
    try {
      Function? exec;

      var readret = json.decode(ret) as Map<String, dynamic>;
      if (!readret.containsKey("result") || !readret.containsKey("requestType")) {
        return;
      }
      switch(readret["requestType"]) {
        case "playback":
          exec = (double pos) => timePos = pos;
          break;
        case "duration":
          exec = (double duration) => this.duration = duration;
          break;
        case "ping":
          exec = (bool pingResult) => _pingResult = pingResult;
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

  // MPVPlayer player = MPVPlayer(verbose: true, timeUpdate: 1);

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
