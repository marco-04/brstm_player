import 'package:brstm_player/brstm.dart';
import 'dart:io';
import 'package:brstm_player/ffmpeg_convert.dart';
import 'package:brstm_player/brstm_player.dart';
import 'dart:async';

void main(List<String> arguments) async {
  String brstmPath = "/tmp/epic_sax.brstm";
  int track = 0;
  var test = BRSTM("./assets/epic_sax.brstm");
  print(r"\\\\\\\\\");
  print(test);

  test.open();
  await test.read();
  // test.readHeaderSync();
  // test.readHeadSync();
  print(r"\\\\\\\\\");
  print(test);

  // convertSync("./assets/epic_sax.brstm", 0, 1, 2, ".");
  // convertSync("./assets/epic_sax.brstm", 0, 1, 2, ".", brstm_converter: false);
  //convertSync("./assets/epic_sax.brstm", 0, 1, 2, ".", brstm_converter: true);

  //brstmPlayer test2 = brstmPlayer(1, 2, 44100, 0, 749491, "./assets/epic_sax.brstm");
  // brstmPlayer test2 = brstmPlayer(1, 2, 32000, 172032, 1552737, "<path_to>/n_skate_F.brstm");
  // await test2.setTrack(0);
  // await test2.play();
  //await test2.init();
  MPVPlayer mpv = MPVPlayer();
  mpv.binary = "mpv";
  // mpv.nTracks = 2;
  mpv.file = "./assets/epic_sax.brstm";
  mpv.pipe = "/tmp/mpvtmp";
  mpv.updateInterval = 300;
  await Process.run("rm", [mpv.pipe]);
  // mpv.pipe = "./mpvtmp";
  await mpv.start();
  await Future.delayed(Duration(seconds: 2));
  await mpv.loadFile(brstmPath);
  await Future.delayed(Duration(seconds: 2));
  await mpv.enableLoop();
  await mpv.setLoopPoint(0);
  await mpv.seek(9.3658);
  await mpv.setLoopPoint(5.376);
  
  // Timer.periodic(Duration(seconds: 5), (timer) {
  //   if (track == 0) {
  //     mpv.switchToTrack(track = 1);
  //   } else {
  //     mpv.switchToTrack(track = 0);
  //   }
  // });
  
  while (mpv.getRunningState()) {
    print(mpv.getTimePos());
    await Future.delayed(Duration(seconds: 1));
  }
  print("Player closed");
}
