class Busao {
  Busao(this.id, this.placa);
  String? placa;
  String? id;
  double? latitude;
  double? longitude;

  Map<String, dynamic> toJson() => {
        'id': id,
        'placa': id,
        'latitude': id,
        'longitude': id,
      };

  setPosition() {}
}
