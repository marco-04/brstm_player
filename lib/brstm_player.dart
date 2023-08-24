import 'dart:io';
import 'package:mpv_dart/mpv_dart.dart';

enum BrstmPlayerSignals { getDuration, getCurrentPos, setCurrentPos, getTrack, setTrack, backwards, forwards, toggle, pause, play }

class brstmPlayer {
  int tracks = 0;
  int channels = 0;
  String name = "";
  String path = "";

  MPVPlayer player = MPVPlayer(verbose: true);

  brstmPlayer(int tracks, int channels, String path) {
    this.tracks = tracks;
    this.channels = channels;
    this.path = path.substring(0, path.lastIndexOf("/"));
    this.name = path.substring(path.lastIndexOf("/")+1, path.length);

    print("${this.path}/${this.name}");
  }

  Future<void> play() async {
    await player.start();
    await player.load("$path/$name");
    sleep(const Duration(seconds: 2));
    await player.goToPosition(30.toDouble());
    await player.command("af", ["set", "lavfi=[pan=4c|c0=c2|c1=c3]"]);
    sleep(const Duration(seconds: 5));
    await player.command("af", ["set", "lavfi=[pan=4c|c0=c0|c1=c1]"]);
    sleep(const Duration(seconds: 5));
    await player.command("af", ["set", "lavfi=[pan=4c|c0=c2|c1=c3]"]);
    sleep(const Duration(seconds: 5));
    await player.quit();
  }

  Future<double> getDuration() async => await player.getDuration();
  Future<double> getCurrentPos() async => await player.getTimePosition();
  Future<int> getTrack() async => tracks;
}
