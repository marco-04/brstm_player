import 'package:brstm_player/brstm.dart';
import 'package:brstm_player/ffmpeg_convert.dart';

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

  convertSync("./assets/epic_sax.brstm", 0, 1, 2, ".");
  convertSync("./assets/epic_sax.brstm", 0, 1, 2, ".", brstm_converter: false);
  convertSync("./assets/epic_sax.brstm", 0, 1, 2, ".", brstm_converter: true);
}
