import 'dart:io';
import 'dart:async';
import 'package:tint/tint.dart';
import 'dart:convert';

const int _MAX_TRACKS = 8;

class MPVPlayer {
  String binary = "";
  String file = "";
  String pipe = "";
  double seconds = 0;
  double loopPoint = 0;
  int curTrack = 0;
  bool loop = false;

  bool isRunning = false;

  double timePos = 0;
  
  // List<String> cmdBuf = List<String>(10);
  
  Process? mpvProcess;
  
  Future<void> start() async {
    if (!await File(pipe).exists()) {
      mpvProcess = await Process.start(binary, [file, "--input-ipc-server=$pipe", "--quiet" ], runInShell: false);

      isRunning = true;

      mpvProcess!.stdout.transform(utf8.decoder).listen((data) {
        print(data);
      });
      mpvProcess!.stderr.transform(utf8.decoder).listen((data) {
        read(data.strip());
        // print(data.strip());
      });

      Timer timeUpdate = Timer.periodic(Duration(milliseconds: 300), (timer) {
        updateTimePos();
      });
    }
  }

  String jsonGen(String property, String requestType) => r'{"result":${' + property + '},"requestType":"$requestType"}';

  Future<void> updateTimePos() async {
    // await send(r'show-text {"result":${time-pos},"requestType":"playback"}');
    await send("show-text ${jsonGen('=time-pos', 'playback')}");
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

  Future<void> quit() async {
    await send("quit");
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
        // case "":
          // break;
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
  
  Future<void> load(String path) async {
    if (mpvProcess != null) {
      await getTimePos();
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
