/* Responsável por: 
  Enviar a localização do ônibus ao usuário.
*/
import 'package:firebase_database/firebase_database.dart';

class Realtime {
  buscaLocalizacao() {
    DatabaseReference starCountRef =
        FirebaseDatabase.instance.ref('localizacaoBusao');

    starCountRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
    });
  }
}
