import 'package:cloud_firestore/cloud_firestore.dart';

class Parada {
  Parada();
  String? thoroughfare;
  String? subThoroughfare;
  String? nome;
  double? latitude;
  double? longitude;
  String? tempoChegadaUsuario;
  String? tempoChegadaBusao;
  String? distanciaAteUsuario;
  String? distanciaAteBusao;
  String? indexRota;

  Parada.fromGeoPoint(GeoPoint geo) {
    latitude = geo.latitude;
    longitude = geo.longitude;
  }
}
