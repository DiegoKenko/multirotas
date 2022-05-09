/* Responsável por: 
  Enviar a localização do ônibus ao usuário.
*/

import 'package:firebase_database/firebase_database.dart';

class Realtime {
  FirebaseDatabase database = FirebaseDatabase.instance;
  FirebaseApp secondaryApp = Firebase.app('SecondaryApp');
  FirebaseDatabase database = FirebaseDatabase.instanceFor(app: secondaryApp);
  // Retorna dados do ônibus como listener
  getLatLong() {}
}
