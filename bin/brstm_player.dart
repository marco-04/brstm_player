import 'package:brstm_player/brstm.dart';
//import 'package:brstm_player/ffmpeg_convert.dart';

void main(List<String> arguments) {
  var test = BRSTM("./assets/epic_sax.brstm");
  print(r"\\\\\\\\\");
  print(test);

  test.openSync();
  test.readHeaderSync();
  test.readHeadSync();
  print(r"\\\\\\\\\");
  print(test);
}
