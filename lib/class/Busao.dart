class Busao {
  Busao(this.id, this.placa);
  String? placa;
  String? id;
  double? latitude;
  double? longitude;

  Busao.fromMap(Map<dynamic, dynamic> data)
      : id = data["id"],
        placa = data["placa"],
        latitude = data["latitude"],
        longitude = data["longitude"];

  Map<String, dynamic> toJson() => {
        'id': id,
        'placa': id,
        'latitude': id,
        'longitude': id,
      };

  setPosition() {}
}
