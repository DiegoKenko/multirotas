class Busao {
  Busao();
  String? placa;
  String? id;
  double? latitude;
  double? longitude;
  double? heading = 0.0;

  Busao.fromMap(Map<dynamic, dynamic> data)
      : id = data["id"],
        placa = data["placa"],
        latitude = data["latitude"],
        longitude = data["longitude"],
        heading =
            data["heading"] == 0 ? data["heading"] + 0.1 : data["heading"];

  Map<String, dynamic> toJson() => {
        'id': id,
        'placa': placa,
        'latitude': latitude,
        'longitude': longitude,
      };
}
