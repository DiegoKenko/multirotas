import 'package:multirotas/class/parada_class.dart';

class Rota {
  Rota();
  String? id;
  String? nome;
  String? busao;
  bool? ida;
  List<Parada>? parada;

  Rota.fromMap(Map<String, dynamic> data) {
    List<Parada> paradas = [];
    List dataParada = data["parada"] as List;
    for (var i = 0; i < dataParada.length; i++) {
      paradas.add(Parada.fromGeoPoint(dataParada[i]));
    }
    id = data["id"];
    busao = data["busao"];
    ida = data["ida"];
    nome = data["nome"];
    parada = paradas;
  }
}
