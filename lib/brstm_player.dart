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
  bool _isPlaying = false;
  // bool _isConnected = false;

  // bool _cancelLoad = false;

  final RegExp _illegalRegExp = RegExp(r'[^a-zA-Z0-9.:\[\]()\ \-_\/\\]');

  bool _pingLock = false;
  bool _pingResult = false;

  Process? mpvProcess;

  Timer? _periodicAction;

  Timer? timeoutCheck;

  void _timeoutCheck(int seconds) {
    timeoutCheck = Timer.periodic(Duration(seconds: seconds), (timer) async {
      if (!_isRunning) {
        timer.cancel();
        timeoutCheck?.cancel();
        return;
      }
      await ping();
      if (!_pingLock) checkIfRunning(seconds);
    });
  }

  ///Start the mpv process. if `hangIndefinitely` is set to `true`,the program will not check if the process is hanging.
  ///
  ///if `hangIndefinitely` is set to `false`, a ping function will be called every `idleDuration` seconds.
  Future<void> start(
      {bool hangIndefinitely = false, int idleDuration = 10}) async {
    if (_isRunning) return;

    try {
      mpvProcess = await Process.start(
          binary, ["--input-ipc-server=$pipe", "--quiet", "--idle=yes"],
          runInShell: false);
    } catch (e) {
      throw Exception("[ERROR]: Cannot start mpv player instance ($e)");
    }

    _isRunning = true;
    // _isConnected = false;
    // _cancelLoad = false;

    mpvProcess!.stdout.transform(utf8.decoder).listen((data) {
      print(data);
    });
    mpvProcess!.stderr.transform(utf8.decoder).listen((data) {
      if (Platform.isLinux) {
        // KILL IT WITH FIRE
        data = data
            .strip()
            .replaceAll(RegExp(r'[^a-zA-Z0-9(){}:.,;"\/\\\[\]\ \-_]'), "")
            .trim();
      } else {
        // We reserved a stronger flamethrower just for dealing with Cringedos
        data = data
            .strip()
            .replaceAll(RegExp("osd-msg3: *"), "")
            .replaceAll(RegExp(r'[^a-zA-Z0-9(){}:.,;"\/\\\[\]\ \-_]'), "")
            .replaceAll(r'\"', '"')
            .trim();
      }
      read(data);
    });
    if (!hangIndefinitely) {
      _timeoutCheck(idleDuration);
    }
  }

  Future<void> setTimeUpdate() async {
    if (!_isPlaying) {
      _periodicAction?.cancel();
      return;
    }

    _periodicAction =
        Timer.periodic(Duration(milliseconds: updateInterval), (timer) async {
      if (!_isPlaying) {
        _periodicAction?.cancel();
        timer.cancel();

        return;
      }

      updateTimePos();
    });
  }

  Future<void> cancelPeriodicAction() async {
    if (_periodicAction != null) {
      _periodicAction!.cancel();
      _periodicAction = null;
    }
  }

  String jsonGen(String property, String requestType) =>
      '{"result":$property,"requestType":"$requestType"}';

  Future<void> checkIfRunning(int seconds) async {
    int timeout = seconds;

    if (!_isRunning) {
      return;
    }
    if (_pingLock) {
      return;
    }

    _pingLock = true;

    while (!_pingResult && timeout > 0) {
      await Future.delayed(Duration(seconds: 1));
      timeout--;
    }

    if (!_pingResult) {
      await cancelPeriodicAction();
      await quit();
      _pingLock = false;
      throw Exception("[ERROR]: Player reply timeout");
    }

    _pingResult = false;
    _pingLock = false;
  }

  Future<void> switchToTrack(int track) async {
    if (nTracks < 2) return;
    if (track < 0 || track >= _MAX_TRACKS) {
      throw Exception("[ERROR]: Invalid track number");
    }
    await send(
        "af set lavfi=[pan=${nTracks * 2}c|c0=c${track * 2}|c1=c${(track * 2) + 1}]");
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
    if (hasIllegalCharacters(file)) {
      throw Exception(
          "[ERROR]: '$file' contains illegal characters: ${_illegalRegExp.allMatches(file).map((match) => match.group(0)).toList()}");
    }
    if (Platform.isWindows) {
      await send("loadfile '$file' replace");
    } else {
      await send("loadfile \"$file\" replace");
    }
    _isPlaying = true;

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
    return _timePos / _duration;
  }

  Future<void> updateTimePos() async {
    await send(
        "${Platform.isLinux ? 'show-text' : 'set osd-msg3'} ${jsonGen(r'${=time-pos}', 'playback')}");
  }

  Future<void> updateCurrentlyPlaying() async {
    await send(
        "${Platform.isLinux ? 'show-text' : 'set osd-msg3'} ${jsonGen(r'"${path}"', 'current')}");
  }

  Future<void> updateDuration() async {
    await send(
        "${Platform.isLinux ? 'show-text' : 'set osd-msg3'} ${jsonGen(r'${=duration}', 'duration')}");
  }

  Future<void> ping() async {
    await send(
        "${Platform.isLinux ? 'show-text' : 'set osd-msg3'} ${jsonGen("true", "ping")}");
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

  Future<void> playPause() async {
    await send("cycle pause");
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      await setTimeUpdate();
    }
  }

  Future<void> play() async {
    _isPlaying = true;
    await setTimeUpdate();
    await send("set pause no");
  }

  Future<void> pause() async {
    _isPlaying = false;
    await send("set pause yes");
  }

  Future<void> setLoopPoint(double seconds) async {
    await send("set ab-loop-a $seconds");
    await send(r"set ab-loop-b ${=duration}");
  }

  Future<void> stop() async {
    _isPlaying = false;
    // _cancelLoad = true;
    await send("stop");
  }

  Future<void> seek(double seconds) async {
    await send("seek $seconds absolute");
  }

  Future<void> quit() async {
    // _cancelLoad = true;
    _isPlaying = false;
    await send("quit");
    _isRunning = false;
  }

  Future<void> send(String cmd) async {
    if (Platform.isLinux) {
      await Process.run("sh", ["-c", "echo '$cmd'" + " | socat - $pipe"]);
    } else {
      await Process.run("cmd", ["/c", "echo $cmd" + ">$pipe"]);
    }
    // if (!_isConnected) {
    //   print("[WARNING]: Could not verify the connection with mpv");
    // }
  }

  double getTimePos() => _timePos;

  double getDuration() => _duration;

  bool getRunningState() => _isRunning;

  bool getPlayerState() => _isPlaying;

  bool hasIllegalCharacters(String str) => str.contains(_illegalRegExp);

  Future<void> read(String ret) async {
    try {
      Function? exec;

      var readret = json.decode(ret) as Map<String, dynamic>;
      if (!readret.containsKey("result") ||
          !readret.containsKey("requestType")) {
        return;
      }
      switch (readret["requestType"]) {
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

  brstmPlayer(int tracks, int channels, int sampleRate, int loopStartSample,
      int duration, String path) {
    // _tracks = tracks;
    // _channels = channels;
    // _sampleRate = sampleRate;
    // _duration = duration;
    // _sduration = getSeconds(duration);
    // _path = path.substring(0, path.lastIndexOf("/"));
    // _name = path.substring(path.lastIndexOf("/")+1, path.length);
  }
}
