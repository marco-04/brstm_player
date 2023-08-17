import 'package:brstm_player/brstm.dart';
import 'package:brstm_player/ffmpeg_convert.dart';

void main(List<String> arguments) {
  //print('Hello world: ${brstm_player.calculate()}!');
  var test = BRSTM("/home/marcosti/Documents/BRSTM/Same Old Story - Hi-Pi.brstm");
  test.open();
  print(test.isBRSTM);
  test.read();
}
