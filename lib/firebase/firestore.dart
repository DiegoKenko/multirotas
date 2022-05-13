import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<List<dynamic>> todasRotas() async {
    List<Map> rotas = [];
    var x = await FirebaseFirestore.instance.collection('rotas').get();
    for (var element in x.docs) {
      rotas.add(element.data());
    }
    return rotas;
  }
}
