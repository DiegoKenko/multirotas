import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:multirotas/class/Rota.dart';
import 'package:multirotas/firebase/firestore.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  static const double latMulti = -19.49392296505924;
  static const double longMult = -44.30632263820034;
  double raioBuscaMetro = 1000;
  bool normalMap = true;
  bool cameraDinamica = true;
  bool mostraRotaAtual = false;
  bool ida = true;
  bool visualizaRotas = false;
  StreamSubscription<Position>? _currentPosition;
  final Geolocator geo = Geolocator();
  CameraPosition _initialLocation = const CameraPosition(
    target: LatLng(latMulti, longMult), // Multitécnica
    zoom: 15,
  );
  late GoogleMapController mapController;
  late PolylinePoints polylinePoints;
  final startAddressController = TextEditingController();
  Map<PolylineId, Polyline> polylines = {};
  List todasRotas = [];
  List rotasProximas = [];
  Set<Marker> markers = {};
  Set<Circle> circles = {};
  late Rota rotaAtual;
  TextEditingController buscaControllerDestino = TextEditingController();
  bool buscandoDestino = false;
  String queryBuscaDestino = "";

  @override
  void initState() {
    super.initState();
    _getRotas();
    _getStremLocation();
  }

  @override
  void dispose() {
    _currentPosition?.cancel();
    _currentPosition = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return SizedBox(
      height: height,
      width: width,
      child: Scaffold(
        drawer: Drawer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(children: [
                ListTile(
                  leading: const Text(
                    'Ida',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  trailing: Switch(
                    inactiveThumbColor: Colors.white,
                    activeColor: Colors.green,
                    value: ida,
                    onChanged: (bool value) {
                      setState(() {
                        ida = value;
                        if (!ida) {
                          visualizaRotas = ida;
                        }
                      });
                    },
                  ),
                ),
                ListTile(
                  leading: const Text(
                    'Exibir todas as rotas',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  trailing: Switch(
                    inactiveThumbColor: Colors.white,
                    activeColor: Colors.green,
                    value: visualizaRotas,
                    onChanged: (bool value) {
                      setState(() {
                        visualizaRotas = value;
                      });
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 20, right: 20, top: 60),
                  child: Text(
                    'alcance',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: SizedBox(
                    child: Slider(
                      thumbColor: Colors.white,
                      divisions: 5,
                      label: '${raioBuscaMetro.round()}',
                      inactiveColor: Colors.amber,
                      value: raioBuscaMetro,
                      onChanged: (value) {
                        setState(() {
                          raioBuscaMetro = value;
                        });
                      },
                      min: 200,
                      max: 2200,
                    ),
                  ),
                ),
                ListTile(
                    leading: const Text(
                      'Estilo do mapa ',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    trailing: IconButton(
                        onPressed: () {
                          setState(() {
                            normalMap = !normalMap;
                          });
                        },
                        icon: Icon(
                          Icons.map,
                          color: normalMap ? Colors.grey : Colors.green,
                        )))
              ]),
            ),
          ),
          elevation: 2,
          backgroundColor: Colors.transparent,
        ),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: ida
              ? Container()
              : Center(
                  child: TextField(
                    controller: buscaControllerDestino,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          buscaRotaPorEndereco();
                        },
                      ),
                      hintText: 'destino...',
                    ),
                  ),
                ),
          actions: const [],
        ),
        body: Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                changeMapMode(mapController);
              },
              markers: Set<Marker>.from(markers),
              //mapToolbarEnabled: true,
              compassEnabled: true,
              polylines: Set<Polyline>.of(polylines.values),
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: normalMap ? MapType.normal : MapType.satellite,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,

              circles: circles,
            ),
            Positioned(
              top: 0,
              bottom: MediaQuery.of(context).size.height * 0.80,
              left: 0,
              right: 0,
              child: mostraRotaAtual
                  ? Container(
                      child: ListTile(
                        title: Center(
                          child: Text(
                            rotaAtual.nome,
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () {
                            setState(() {
                              mostraRotaAtual = false;
                              polylines.clear();
                            });
                          },
                          icon: const Icon(Icons.close, size: 40),
                        ),
                      ),
                      height: 40,
                      color: const Color.fromRGBO(255, 255, 255, 0.4),
                    )
                  : Container(),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.75,
              left: MediaQuery.of(context).size.width * 0.75,
              child: ClipOval(
                child: SizedBox(
                  child: IconButton(
                    icon: Icon(
                      Icons.navigation,
                      color: cameraDinamica
                          ? const Color(0xFF57C0A4)
                          : Colors.grey,
                      size: 50,
                    ),
                    onPressed: () {
                      cameraDinamica = !cameraDinamica;
                    },
                  ),
                  height: 70,
                  width: 70,
                ),
              ),
            ),
            visualizaRotas
                ? Positioned.fill(
                    bottom: 0,
                    top: MediaQuery.of(context).size.height * 0.8,
                    left: 0,
                    right: 0,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: todasRotas.length,
                      itemBuilder: (context, index) {
                        return cardRota(todasRotas[index]);
                      },
                    ),
                  )
                : Container()
          ],
        ),
      ),
    );
  }

  // Atualização da localização como stream.
  // É possível utilizar 'await Geolocator.getCurrentPosition'
  _getStremLocation() async {
    _currentPosition = Geolocator.getPositionStream(
      desiredAccuracy: LocationAccuracy.high,
    ).listen((event) {
      _initialLocation = CameraPosition(
        target: LatLng(
          event.latitude,
          event.longitude,
        ),
      );
      if (cameraDinamica) {
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                _initialLocation.target.latitude,
                _initialLocation.target.longitude,
              ),
              zoom: 15,
            ),
          ),
        );
      }
      if (ida) {
        _rotasProximasIda();
      }
      attCircle();
    });
  }

  Future<Polyline> _createPolylines(
    double startLatitude,
    double startLongitude,
    double destinationLatitude,
    double destinationLongitude,
    String nomeId,
    List<PolylineWayPoint> paradas,
  ) async {
    // Initializing PolylinePoints
    List<LatLng> polylineCoordinates = [];
    polylinePoints = PolylinePoints();

    // Generating the list of coordinates to be used for drawing the polylines
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyC-cAQ95icIXxAelzKYLjwVVDCw-KFmuBw', // Google Maps API Key
      PointLatLng(
        startLatitude,
        startLongitude,
      ),
      PointLatLng(
        destinationLatitude,
        destinationLongitude,
      ),
      wayPoints: paradas,
      travelMode: TravelMode.driving,
    );

    // Adding the coordinates to the list
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(
          LatLng(
            point.latitude,
            point.longitude,
          ),
        );
      }
    }

    // Defining an ID
    PolylineId id = PolylineId(nomeId);

    // Initializing Polyline
    Polyline polyline = Polyline(
      polylineId: id,
      color: const Color.fromARGB(255, 241, 112, 7),
      points: polylineCoordinates,
      width: 3,
    );

    // Adding the polyline to the map
    return polyline;
  }

  // Atualização stream da localização dos ônibus
  // Os ônibus são identificados como marcadores
  _getRotas() async {
    todasRotas = await Firestore().todasRotas(ida);
  }

  Widget cardRota(Rota rota) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      child: Card(
        shadowColor: Colors.white,
        child: GestureDetector(
          onTap: () {
            polylines.clear();
            montaPolyline(rota);
          },
          child: Center(
              child: Text(
            rota.nome,
            style: const TextStyle(
              color: Colors.white,
              letterSpacing: 2,
            ),
          )),
        ),
        color: const Color(0xFF373D69),
      ),
    );
  }

  Future<void> _rotasProximasIda() async {
    final markerMult = await markerMulti();
    var iconMarkerParada = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(100, 100)), "assets/paradaMap.png");
    Set<Marker> tempMarker = {};
    List<Rota> rotasProximas = await Firestore().rotasProximas(
        double.parse(_initialLocation.target.latitude.toString()),
        double.parse(_initialLocation.target.longitude.toString()),
        raioBuscaMetro / 1000,
        ida);
    for (var i = 0; i < rotasProximas.length; i++) {
      for (var j = 0; j < rotasProximas[i].parada.length; j++) {
        Rota rotaTempProx = rotasProximas[i];
        Marker markTemp = Marker(
          zIndex: i * 10.0 + j,
          onTap: () {
            Rota rotaTemp = todasRotas
                .firstWhere((element) => (element.id == rotaTempProx.id));
            setState(() {
              rotaAtual = rotaTemp;
              montaPolyline(rotaTemp);
              visualizaRotas = false;
              mostraRotaAtual = true;
              cameraDinamica = false;
            });
          },
          markerId: MarkerId(rotasProximas[i].nome + '|' + j.toString()),
          position: LatLng(rotasProximas[i].parada[j].latitude,
              rotasProximas[i].parada[j].longitude),
          infoWindow: InfoWindow(
            title: rotasProximas[i].nome,
            snippet: rotasProximas[i].parada[j].latitude.toString() +
                ' | ' +
                rotasProximas[i].parada[j].longitude.toString(),
          ),
          icon: iconMarkerParada,
        );
        tempMarker.add(markTemp);
      }
    }
    setState(() {
      markers.clear();
      tempMarker.add(markerMult);
      markers = tempMarker;
    });
  }

  Future<Marker> markerMulti() async {
    var iconMarkerMulti = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(100, 100)), "assets/mtMap.png");
    return Marker(
      markerId: const MarkerId('mt'),
      position: const LatLng(latMulti, longMult),
      infoWindow: const InfoWindow(
        title: 'Grupo Multitécnica',
      ),
      icon: iconMarkerMulti,
    );
  }

  attCircle() {
    setState(() {
      circles = {
        Circle(
          fillColor: const Color.fromARGB(43, 94, 125, 212),
          strokeColor: const Color.fromRGBO(148, 169, 229, 0.2),
          circleId: const CircleId('id'),
          center: LatLng(_initialLocation.target.latitude,
              _initialLocation.target.longitude),
          radius: raioBuscaMetro,
        )
      };
    });
  }

  montaPolyline(Rota rota) {
    List<PolylineWayPoint> wayPoints = [];
    // Adiciona cada parada, exceto a primeira e a última
    for (var i = 1; i < rota.parada.length - 1; i++) {
      wayPoints.add(
        PolylineWayPoint(
          location: rota.parada[i].latitude.toString() +
              ',' +
              rota.parada[i].longitude.toString(),
        ),
      );
    }
    _createPolylines(
      rota.parada[0].latitude,
      rota.parada[0].longitude,
      rota.parada[rota.parada.length - 1].latitude,
      rota.parada[rota.parada.length - 1].longitude,
      rota.nome,
      wayPoints,
    ).then(
      (value) {
        polylines.clear();
        setState(
          () {
            polylines[value.polylineId] = value;
          },
        );
      },
    );
  }

  // Alteração do layout do map
  void changeMapMode(GoogleMapController mapController) {
    getJsonFile("assets/mapStyle.json")
        .then((value) => setMapStyle(value, mapController));
  }

  //helper function
  void setMapStyle(String mapStyle, GoogleMapController mapController) {
    mapController.setMapStyle(mapStyle);
  }

  //helper function
  Future<String> getJsonFile(String path) async {
    ByteData byte = await rootBundle.load(path);
    var list = byte.buffer.asUint8List(byte.offsetInBytes, byte.lengthInBytes);
    return utf8.decode(list);
  }

  // Busca as rotas mais próxima dentro do raio do endereço(lat long) passado
  buscaRotaPorEndereco() async {
    var iconMarkerParada = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(100, 100)), "assets/paradaMap.png");
    int counter = 0;
    Set<Marker> markerVolta = {};
    // adiciona 'sete lagoas' na busca do endereço
    String endereco = buscaControllerDestino.text + 'sete lagoas';
    List<Location> locais =
        await locationFromAddress(endereco, localeIdentifier: 'pt_BR');

    // para cada local encontrado, deve-se adicionar um marcador, ao clicar no marcador, apresentará as rotas próximas.
    for (var element in locais) {
      counter++;
      markerVolta.add(Marker(
        onTap: () {},
        markerId: MarkerId(counter.toString()),
        position: LatLng(element.latitude, element.longitude),
        infoWindow: InfoWindow(title: buscaControllerDestino.text),
        onDrag: (obj) {},
        icon: iconMarkerParada,
      ));
      setState(() {
        markers.clear();
        markers = markerVolta;
        cameraDinamica = false;
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                element.latitude,
                element.longitude,
              ),
              zoom: 14,
            ),
          ),
        );
      });
    }
  }

  Future<void> _rotasProximasVolta(Position pos) async {
    final markerMult = await markerMulti();
    var iconMarkerParada = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(100, 100)), "assets/paradaMap.png");
    Set<Marker> tempMarker = {};
    List<Rota> rotasProximas = await Firestore().rotasProximas(
        double.parse(pos.latitude.toString()),
        double.parse(pos.longitude.toString()),
        raioBuscaMetro / 1000,
        ida);
    for (var i = 0; i < rotasProximas.length; i++) {
      for (var j = 0; j < rotasProximas[i].parada.length; j++) {
        Rota rotaTempProx = rotasProximas[i];
        Marker markTemp = Marker(
          zIndex: i * 10.0 + j,
          onTap: () {
            Rota rotaTemp = todasRotas
                .firstWhere((element) => (element.id == rotaTempProx.id));
            setState(() {
              rotaAtual = rotaTemp;
              montaPolyline(rotaTemp);
              visualizaRotas = false;
              mostraRotaAtual = true;
              cameraDinamica = false;
            });
          },
          markerId: MarkerId(rotasProximas[i].nome + '|' + j.toString()),
          position: LatLng(rotasProximas[i].parada[j].latitude,
              rotasProximas[i].parada[j].longitude),
          infoWindow: InfoWindow(
            title: rotasProximas[i].nome,
            snippet: rotasProximas[i].parada[j].latitude.toString() +
                ' | ' +
                rotasProximas[i].parada[j].longitude.toString(),
          ),
          icon: iconMarkerParada,
        );
        tempMarker.add(markTemp);
      }
    }
    setState(() {
      markers.clear();
      tempMarker.add(markerMult);
      markers = tempMarker;
    });
  }
}
