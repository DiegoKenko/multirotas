/* Responsável por: 
  Enviar a localização do ônibus ao usuário.
*/
import 'package:firebase_database/firebase_database.dart';
import 'package:multirotas/class/rota.dart';

class Realtime {
  Stream<DatabaseEvent> buscaBusao(Rota rota) {
    return FirebaseDatabase.instance.ref('localizacaoBusao/' + rota.id).onValue;
  }
}
