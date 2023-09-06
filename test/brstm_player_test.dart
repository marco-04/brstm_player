import 'dart:convert';
import 'dart:io';

void main() async {
  final process = await Process.start('mpv', ['assets/epic_sax.brstm'],
      runInShell: false);

  await process.stdout.transform(utf8.decoder).listen((data) {
    // Questo ascolta l'output standard del processo mpv.
    print('Output mpv: $data');
    // Analizza i dati per ottenere le informazioni desiderate, come il secondo corrente.
  });

  process.stderr.transform(utf8.decoder).listen((data) {
    // Questo ascolta l'output degli errori del processo mpv.
    print(data);
  });

  // Gestione della segnalazione di interruzione (Ctrl+C).
  ProcessSignal.sigint.watch().listen((_) {
    print(
        'Ricevuta segnalazione di interruzione (Ctrl+C). Terminazione di mpv...');
    process.kill(ProcessSignal.sigint);
    //return;
    exit(1);
  });

  // Aspetta che il processo mpv finisca.
  final exitCode = await process.exitCode;
  print('mpv ha terminato con codice di uscita $exitCode');
}
