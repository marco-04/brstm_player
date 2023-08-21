import 'dart:io';

Future<void> convert(String path, int codec, int tracks, int channels, String dest, {bool brstm_converter = false}) async {
  if ((channels/tracks) != 2 && (channels/tracks) != 1) {
    throw Exception("[FAILED]: Uneven channels($channels)/track($tracks) ratio");
  }
  
  // TO CHANGE ON WINDOWS
  final String dest_file = "${path.substring(path.lastIndexOf("/")+1, path.lastIndexOf("."))}.wav";
  //final String ffmpeg_convert = "ffmpeg -y -i '$path' -c:a pcm_s32le '$dest$dest_file'";
  //final String ffmpeg_split_s = "ffmpeg -y -i '$dest$dest_file' -af 'pan=${channels}c|";
  ProcessResult? process;
  
  assert(File(path).existsSync());
  
  if (!brstm_converter) {
    process = await Process.run(
      "ffmpeg",
      [
        "-y",
        "-i",
        "$path",
        "-c:a",
        "pcm_s16le",
        "$dest/$dest_file"
      ]
    );
  } else {
    process = await Process.run(
      "brstm_converter",
      [
        "$path",
        "-o",
        "$dest/$dest_file"
      ]
    );
  }
  
  print(process.stdout);
  print(process.stderr);

  if (tracks > 1) {
    for (int i = 0; i < tracks; i++) {
      process = await Process.run(
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

void convertSync(String path, int codec, int tracks, int channels, String dest, {bool brstm_converter = false}) {
  if ((channels/tracks) != 2 && (channels/tracks) != 1) {
    throw Exception("[FAILED]: Uneven channels($channels)/track($tracks) ratio");
  }
  
  // TO CHANGE ON WINDOWS
  final String dest_file = "${path.substring(path.lastIndexOf("/")+1, path.lastIndexOf("."))}.wav";
  //final String ffmpeg_convert = "ffmpeg -y -i '$path' -c:a pcm_s32le '$dest$dest_file'";
  //final String ffmpeg_split_s = "ffmpeg -y -i '$dest$dest_file' -af 'pan=${channels}c|";
  ProcessResult? process;
  
  assert(File(path).existsSync());
  
  if (!brstm_converter) {
    process = Process.runSync(
      "ffmpeg",
      [
        "-y",
        "-i",
        "$path",
        "-c:a",
        "pcm_s16le",
        "$dest/$dest_file"
      ]
    );
  } else {
    process = Process.runSync(
      "brstm_converter",
      [
        "$path",
        "-o",
        "$dest/$dest_file"
      ]
    );
  }
  
  print(process.stdout);
  print(process.stderr);
  
  if (tracks > 1) {
    for (int i = 0; i < tracks; i++) {
      process = Process.runSync(
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
