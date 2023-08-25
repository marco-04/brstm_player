import 'dart:io';
import 'package:mpv_dart/mpv_dart.dart';

const int _MAX_TRACKS = 8;

class brstmPlayer {
  int _tracks = 0;
  int _channels = 0;
  int _sampleRate = 0;
  int _duration = 0;
  double _sduration = 0;
  double _loopPoint = 0;
  String _name = "";
  String _path = "";

  int _curTrack = 0;

  String? _filter;

  MPVPlayer player = MPVPlayer(verbose: true, timeUpdate: 1);

  dynamic _loopEvent;

  brstmPlayer(int tracks, int channels, int sampleRate, int loopStartSample, int duration, String path) {
    _tracks = tracks;
    _channels = channels;
    _sampleRate = sampleRate;
    _duration = duration;
    _sduration = getSeconds(duration);
    _path = path.substring(0, path.lastIndexOf("/"));
    _name = path.substring(path.lastIndexOf("/")+1, path.length);

    setLoopPoint(loopStartSample);
  }

  Future<void> setPosition(double seconds) async {
    if (seconds < 0 || seconds >= await player.getDuration()) {
      throw Exception("[FAILED]: Invalid track number");
    }
    if (!await player.isRunning()) {
      throw Exception("[FAILED]: mpv is not running");
    }
  }

  Future<void> init() async {
    // _loopEvent = player.on("timeposition", _sduration = getSeconds(_duration), (ev, context) => player.goToPosition(_loopPoint));
    _loopEvent = player.on("stopped", null, (ev, context) => player.goToPosition(_loopPoint));
  }

  Future<void> setTrack(int track) async {
    if (track < 0 || track >= _MAX_TRACKS) {
      throw Exception("[FAILED]: Invalid track number");
    }

    int c0 = track*2;
    int c1 = (track*2)+1;
    _filter = "lavfi=[pan=${_channels}c|c0=c$c0|c1=c$c1]";

    _curTrack = track;
  }

  Future<void> updateTrack() async {
    try {
      await applyFilter(_filter as String);
    } catch (e) {
      throw Exception("[FAILED]: Could not switch audio tracks ($e)");
    }
  }

  Future<void> applyFilter(String filter) async => await player.command("af", ["set", filter]);

  Future<void> play() async {
    await player.start();
    if (_filter == null) {
      throw Exception("[FAILED]: No audio track selected");
    }
    await player.load("$_path/$_name");

    // await player.loop('inf');

    sleep(Duration(seconds: _loopPoint.toInt()));

    player.on(MPVEvents.timeposition, null, (ev,context) => print(ev.eventData));

    player.goToPosition(44.toDouble());

    print ("$_loopPoint - $_sduration");

    // updateTrack();
    while (await player.getDuration() < _loopPoint);
    player.on(MPVEvents.stopped, null, (ev, context) async {
    //player.on(MPVEvents.timeposition, null, (ev, context) {
        await player.load("$_path/$_name");
        sleep(Duration(milliseconds: 4));
        await player.goToPosition(_loopPoint);
    });
  }

  Future<double> getCurrentPos() async => await player.getTimePosition();
  double getDuration() => _sduration;
  int getTrack() => _curTrack;
  int getSamples(double seconds) => (_sampleRate.toDouble()*seconds).toInt();
  double getSeconds(int samples) => samples/_sampleRate;
  void setLoopPoint(int loopStartSample) => _loopPoint = getSeconds(loopStartSample);

  // Future<int> setDuration(double seconds) async => _duration = await getSamples(await player.getDuration());
}
