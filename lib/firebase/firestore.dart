import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:multirotas/class/Rota.dart';
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

  Future<List<Rota>> rotasProximas(double lat, double long) async {
    double distanciaMax = 2; // Em kilometros
    List<Rota> rotas = [];
    var x = await FirebaseFirestore.instance.collection('rotas').get();
    for (var element in x.docs) {
      Rota r = Rota.fromMap(element.data());
      for (var p = r.parada.length - 1; p >= 0; p--) {
        // se está fora do raio mínimo, remove da lista
        if (Haversine.haversine(
                lat, long, r.parada[p].latitude, r.parada[p].longitude) >
            distanciaMax) {
          r.parada.removeAt(p);
        }
      }
      if (r.parada.isNotEmpty) {
        rotas.add(r);
      }
    }
    return rotas;
  }
}
