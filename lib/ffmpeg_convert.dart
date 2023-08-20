import 'dart:io';

Future<void> convert(String path, int codec, int tracks, int channels, String dest) async {
  if ((channels/tracks) != 2 && (channels/tracks) != 1) {
    throw Exception("[FAILED]: Uneven channels($channels)/track($tracks) ratio");
  }
  
  // TO CHANGE ON WINDOWS
  final String dest_file = "${path.substring(path.lastIndexOf("/")+1, path.lastIndexOf("."))}.wav";
  //final String ffmpeg_convert = "ffmpeg -y -i '$path' -c:a pcm_s32le '$dest$dest_file'";
  //final String ffmpeg_split_s = "ffmpeg -y -i '$dest$dest_file' -af 'pan=${channels}c|";
  
  assert(File(path).existsSync());
  
  var process = await Process.run(
    "ffmpeg",
    [
      "-y",
      "-i",
      "$path",
      "-c:a",
      "pcm_s32le",
      "$dest/$dest_file"
    ]
  );
  
  print(process.stdout);
  print(process.stderr);
  
  if (tracks > 1) {
    for (int i = 0; i < tracks; i++) {
      var process = await Process.run(
        "ffmpeg",
        [
          "-y",
          "-i",
          "$dest/$dest_file",
          "-af",
          "pan=${channels}c|c0=c${i*2}|c1=c${(i*2)+1}",
          "-ac",
          "2",
          "$dest/T$i-$dest_file"
        ]
      );
      
      print(process.stdout);
      print(process.stderr);
    }
  }
}