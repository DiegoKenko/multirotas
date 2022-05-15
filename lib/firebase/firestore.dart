import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multirotas/class/Rota.dart';

class Firestore {
  Map<String, dynamic>? buscaRota(String id) {
    FirebaseFirestore.instance.collection('rotas').doc(id).get().then(
      (event) {
        if (event.exists) {
          return event.data();
        }
      },
    );
    return null;
  }

  Future<List<Rota>> todasRotas() async {
    List<Rota> rotas = [];
    var x = await FirebaseFirestore.instance.collection('rotas').get();
    for (var element in x.docs) {
      rotas.add(Rota.fromMap(element.data()));
    }
    return rotas;
  }
}
