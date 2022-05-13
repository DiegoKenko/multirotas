// ignore_for_file: file_names

class Rota {
  String id;
  String nome;
  String busao;
  bool ida;
  List<Object?> parada;

  Rota.fromMap(Map<String, dynamic> data)
      : id = data["id"],
        busao = data["busao"],
        ida = data["id"],
        nome = data["nome"],
        parada = data["parada"];
}
