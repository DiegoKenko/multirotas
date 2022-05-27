import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multirotas/class/rota.dart';
import 'package:multirotas/location/haversine.dart';

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

  Future<List<Rota>> rotasProximas(
      double latPosAtual, double longPosAtual, double raioKm, bool ida) async {
    double distanciaMinMulti = 1; // Em kilometros
    double latMulti = -19.49392296505924;
    double longMulti = -44.30632263820034;
    List<Rota> rotas = [];
    var x = await FirebaseFirestore.instance
        .collection('rotas')
        .where('ida', isEqualTo: ida)
        .get();
    for (var element in x.docs) {
      Rota r = Rota.fromMap(element.data());
      for (var p = r.parada.length - 1; p >= 0; p--) {
        // se está fora do raio mínimo, remove da lista
        if (Haversine.haversine(latPosAtual, longPosAtual, r.parada[p].latitude,
                r.parada[p].longitude) >
            raioKm) {
          r.parada.removeAt(p);
        } else {
          // desconsidera paradas no raio de 1km da Multi
          if (Haversine.haversine(latMulti, longMulti, r.parada[p].latitude,
                  r.parada[p].longitude) <=
              distanciaMinMulti) {
            r.parada.removeAt(p);
          }
        }
      }
      if (r.parada.isNotEmpty) {
        rotas.add(r);
      }
    }
    return rotas;
  }
}
