import 'package:brstm_player/brstm.dart';
import 'dart:io';
import 'package:brstm_player/ffmpeg_convert.dart';
import 'package:brstm_player/brstm_player.dart';

void main(List<String> arguments) async {
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
  mpv.file = "./assets/epic_sax.brstm";
  mpv.pipe = "/tmp/mpvtmp";
  await Process.run("rm", [mpv.pipe]);
  // mpv.pipe = "./mpvtmp";
  await mpv.start();
  await Future.delayed(Duration(seconds: 2));
  await mpv.enableLoop();
  await mpv.setLoopPoint(5.376);
  while (mpv.isRunning) {
    print(mpv.getTimePos());
    await Future.delayed(Duration(seconds: 1));
  }
}
