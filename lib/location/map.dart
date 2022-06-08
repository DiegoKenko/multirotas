import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:multirotas/class/rota.dart';
import 'package:multirotas/firebase/firestore.dart';
import 'package:dio/dio.dart';
import 'package:multirotas/firebase_options.dart';
import 'package:multirotas/location/haversine.dart';

import '../class/parada.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final Color rotaColor = const Color.fromARGB(255, 255, 145, 0);
  final Color busaoColor = const Color.fromARGB(255, 0, 102, 255);
  final Color usuarioColor = const Color.fromARGB(106, 19, 232, 0);
  static const double latMulti = -19.49392296505924;
  static const double longMult = -44.30632263820034;
  double raioBuscaMetro = 600;
  bool normalMap = true;
  bool cameraDinamica = false;
  bool mostraRotaAtual = false;
  bool mostraParadaAtual = false;
  bool ida = true;
  bool mapTapAllowed = false;
  StreamSubscription<Position>? _currentPositionStream;
  CameraPosition _initialLocation = const CameraPosition(
    target: LatLng(latMulti, longMult), // Multitécnica
    zoom: 16,
  );
  late GoogleMapController mapController;
  late PolylinePoints polylinePoints;
  final startAddressController = TextEditingController();
  Map<PolylineId, Polyline> polylines = {};
  List todasRotas = [];
  List todasRotasProximas = [];
  List rotasProximas = [];
  Set<Marker> markers = {};
  Set<Circle> circles = {};
  late Rota rotaAtual;
  late Parada paradaAtual = Parada();
  TextEditingController buscaControllerDestino = TextEditingController();
  @override
  void initState() {
    super.initState();
    _getStremLocation();
    // Deve ser executado depois do _getStremLocation
    getRotas();
  }

  @override
  void dispose() {
    _currentPositionStream?.cancel();
    _currentPositionStream = null;
    mapController.dispose();
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
        drawerScrimColor: const Color.fromARGB(144, 0, 0, 0),
        drawer: Drawer(
          elevation: 2,
          backgroundColor: Color.fromARGB(255, 55, 61, 105),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  ListTile(
                    leading: const Text(
                      'Caminho de ida até a Multitécnica',
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
                          limpaMarcacoes();
                        });
                      },
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
                            color: normalMap ? Colors.grey : Colors.amber,
                          )))
                ],
                mainAxisAlignment: MainAxisAlignment.start,
              ),
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF373D69),
          actions: const [],
          title: ida
              ? Container()
              : Center(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    controller: buscaControllerDestino,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () {
                          limpaMarcacoes();
                          FocusScope.of(context).unfocus(); // esconder teclado
                          buscaRotaPorEndereco();
                        },
                      ),
                      hintText: 'destino...',
                      hintStyle: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
        ),
        body: Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            GoogleMap(
              onCameraMove: (position) {
                setState(() {
                  cameraDinamica = false;
                });
              },
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                changeMapMode(mapController);
              },
              onTap: (pos) async {
                if (mapTapAllowed && ida) {
                  var iconMarkerParada = await BitmapDescriptor.fromAssetImage(
                      const ImageConfiguration(size: Size(100, 100)),
                      "assets/paradaMap.png");
                  Parada paradaAtualTemp;
                  Marker markerM = await markerMulti();
                  LatLng? paradaLatLng = await buscaParadaProxima(pos);
                  paradaAtualTemp = await detalhesParada(
                      rotaAtual,
                      paradaLatLng!,
                      const LatLng(latMulti, longMult),
                      _initialLocation.target);
                  if (paradaAtual != paradaAtualTemp) {
                    setState(
                      () {
                        paradaAtual = paradaAtualTemp;
                        mostraParadaAtual = true;

                        // Adiciona marcadores
                        markers.clear();
                        markers.add(markerM);
                        markers.add(
                          Marker(
                            anchor: const Offset(0.5, 0.5),
                            markerId: const MarkerId("nearestMarker"),
                            position: paradaLatLng,
                            icon: iconMarkerParada,
                          ),
                        );
                        // Cria polilynes
                        _createPolylines(
                                _initialLocation.target.latitude,
                                _initialLocation.target.longitude,
                                paradaAtual.latitude!,
                                paradaAtual.longitude!,
                                'trajetoUsuario',
                                [],
                                usuarioColor,
                                5)
                            .then((value) {
                          polylines[value.polylineId] = value;
                        });
                        // Muda camera
                        mapController.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(
                                paradaLatLng.latitude,
                                paradaLatLng.longitude,
                              ),
                              zoom: 16,
                            ),
                          ),
                        );
                      },
                    );
                  }
                }
              },
              markers: Set<Marker>.from(markers),
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
              left: 0,
              bottom: MediaQuery.of(context).size.height * 0.7,
              right: 0,
              child: mostraRotaAtual
                  ? Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(225, 255, 255, 255),
                            border: Border.all(
                                color: const Color(0xFF373D69), width: 2),
                          ),
                          child: ListTile(
                            tileColor: Colors.amberAccent,
                            title: Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    rotaAtual.nome,
                                    style: const TextStyle(fontSize: 30),
                                  ),
                                ),
                                mostraParadaAtual
                                    ? Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(paradaAtual.thoroughfare! +
                                            ', ' +
                                            paradaAtual.subThoroughfare!),
                                      )
                                    : const Text(''),
                              ],
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                setState(() {
                                  mostraRotaAtual = false;
                                  mapTapAllowed = false;
                                  limpaMarcacoes();
                                });
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 35,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                        if (mostraParadaAtual)
                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(225, 255, 255, 255),
                              border: Border.all(
                                  color: const Color(0xFF373D69), width: 1),
                            ),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: 40,
                              child: ListView(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(Icons.directions_walk),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(paradaAtual.tempoChegadaUsuario
                                        .toString()),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(paradaAtual.distanciaAteUsuario
                                        .toString()),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(Icons.directions_bus_rounded),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(paradaAtual.tempoChegadaBusao
                                        .toString()),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(paradaAtual.distanciaAteBusao
                                        .toString()),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(),
                      ],
                    )
                  : Container(),
            ),
            ida
                ? DraggableScrollableSheet(
                    minChildSize: 0.1,
                    initialChildSize: 0.1,
                    maxChildSize: 0.5,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: todasRotasProximas.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.only(left: 5, right: 5),
                                child: Center(
                                  child: Text(
                                    'Rotas:',
                                    style: TextStyle(
                                      color: Color(0xFF373D69),
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ),
                              ),
                              shadowColor: Colors.white,
                              color: Color.fromARGB(255, 240, 224, 4),
                            );
                          } else {
                            return cardRota(todasRotasProximas[index - 1]);
                          }
                        },
                      );
                    },
                  )
                : Container(),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.7,
              left: MediaQuery.of(context).size.width * 0.75,
              child: ClipOval(
                child: SizedBox(
                  child: ClipOval(
                    child: Material(
                      color: Colors.white54,
                      child: InkWell(
                        splashColor: Colors.blue,
                        child: IconButton(
                          icon: Icon(
                            Icons.my_location,
                            color: cameraDinamica
                                ? const Color(0xFF373D69)
                                : Colors.grey,
                            size: 40,
                          ),
                          onPressed: () {
                            setState(() {
                              cameraDinamica = !cameraDinamica;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  height: 70,
                  width: 70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  getRotas() async {
    todasRotas = await Firestore().todasRotas();
  }

  // Atualização da localização como stream.
  // É possível utilizar 'await Geolocator.getCurrentPosition'
  _getStremLocation() async {
    Geolocator.getCurrentPosition().then(
      (value) => {
        _initialLocation = CameraPosition(
          target: LatLng(
            value.latitude,
            value.longitude,
          ),
        ),
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                _initialLocation.target.latitude,
                _initialLocation.target.longitude,
              ),
              zoom: 16,
            ),
          ),
        ),
        setState(
          () {},
        )
      },
    );
    _currentPositionStream = Geolocator.getPositionStream(
      intervalDuration: const Duration(seconds: 5),
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
              zoom: 16,
            ),
          ),
        );
      }
      if (ida) {
        _rotasProximasIda();
        setState(() {
          attCircle(LatLng(_initialLocation.target.latitude,
              _initialLocation.target.longitude));
        });
      }
    });
  }

  Future<Polyline> _createPolylines(
      double startLatitude,
      double startLongitude,
      double destinationLatitude,
      double destinationLongitude,
      String nomeId,
      List<PolylineWayPoint> paradas,
      Color cor,
      int largura) async {
    // Limpa polylineAtual
    polylines[PolylineId(nomeId)] = Polyline(polylineId: PolylineId(nomeId));

    // Initializing PolylinePoints
    List<LatLng> polylineCoordinates = [];
    polylinePoints = PolylinePoints();

    // Generating the list of coordinates to be used for drawing the polylines
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      DefaultFirebaseOptions.android.apiKey, // Google Maps API Key
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
      color: cor,
      points: polylineCoordinates,
      width: largura,
    );

    // Adding the polyline to the map
    return polyline;
  }

  Widget cardRota(Rota rota) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(right: 10, left: 10),
      width: MediaQuery.of(context).size.width * 0.7,
      child: GestureDetector(
        child: Card(
          child: Center(
            child: Text(
              rota.nome,
              style: const TextStyle(
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          shadowColor: Colors.white,
          color: const Color(0xFF373D69),
        ),
        onTap: () {
          limpaMarcacoes();
          if (ida || rota.parada.isNotEmpty) {
            mapTapAllowed = true;
            rotaAtual = todasRotas.firstWhere(
              (element) => (element.id == rota.id),
            );
            montaPolyline(rotaAtual);
            setState(() {
              mostraRotaAtual = true;
            });
          }
        },
      ),
    );
  }

  Future<void> _rotasProximasIda() async {
    List<Rota> todasRotasTemp = [];

    List<Rota> rotasProximas = await Firestore().rotasProximas(
        double.parse(_initialLocation.target.latitude.toString()),
        double.parse(_initialLocation.target.longitude.toString()),
        raioBuscaMetro / 1000,
        ida);
    for (var i = 0; i < rotasProximas.length; i++) {
      todasRotasTemp.add(rotasProximas[i]);
    }
    setState(() {
      todasRotasProximas = todasRotasTemp;
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

  attCircle(LatLng latLng) {
    circles = {
      Circle(
        fillColor: const Color.fromARGB(43, 94, 125, 212),
        strokeColor: const Color.fromRGBO(148, 169, 229, 0.2),
        circleId: const CircleId('id'),
        center: LatLng(latLng.latitude, latLng.longitude),
        radius: raioBuscaMetro,
      )
    };
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
            rotaColor,
            10)
        .then(
      (value) {
        limpaMarcacoes();
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
    var latLng = LatLng(locais.first.latitude, locais.first.longitude);
    _rotasProximasVolta(latLng);
    counter++;
    markerVolta.add(Marker(
      markerId: MarkerId(counter.toString()),
      position: LatLng(locais.first.latitude, locais.first.longitude),
      infoWindow: InfoWindow(title: buscaControllerDestino.text),
      icon: iconMarkerParada,
    ));

    setState(() {
      limpaMarcacoes();
      markers = markerVolta;
      cameraDinamica = false;
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              locais.first.latitude,
              locais.first.longitude,
            ),
            zoom: 16,
          ),
        ),
      );
      attCircle(latLng);
    });
  }

  Future<void> _rotasProximasVolta(LatLng pos) async {
    final markerMult = await markerMulti();
    final markerDestino = Marker(
      markerId: MarkerId(pos.toString()),
      position: LatLng(pos.latitude, pos.longitude),
      infoWindow: InfoWindow(title: buscaControllerDestino.text),
      onDrag: (obj) {},
    );
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
              montaPolyline(rotaTemp);
              rotaAtual = rotaTemp;
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
      tempMarker.add(markerMult);
      tempMarker.add(markerDestino);
      markers = tempMarker;
    });
  }

  listaDeParadas(Rota rota) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            rota.parada[index].nome,
            style: const TextStyle(fontSize: 18),
          ),
          subtitle: Text(
            rota.parada[index].latitude.toString() +
                ' | ' +
                rota.parada[index].longitude.toString(),
            style: const TextStyle(fontSize: 14),
          ),
        );
      },
      itemCount: rota.parada.length,
    );
  }

  Future<Parada> detalhesParada(
    Rota rota,
    LatLng posParada,
    LatLng posBusao,
    LatLng posUsuario,
  ) async {
    String travelModeBusao = "driving";
    String travelModeUsuario = "walking";
    Parada parada = Parada();
    List<Placemark> lugares =
        await placemarkFromCoordinates(posParada.latitude, posParada.longitude);
    parada.thoroughfare = lugares.first.thoroughfare;
    parada.subThoroughfare = lugares.first.subThoroughfare;
    // Do usuário até a parada
    var retUsu = await Dio().get(
        'https://maps.googleapis.com/maps/api/distancematrix/json?destinations=' +
            posUsuario.latitude.toString() +
            ',' +
            posUsuario.longitude.toString() +
            '&origins=' +
            posParada.latitude.toString() +
            ',' +
            posParada.longitude.toString() +
            '&key=' +
            DefaultFirebaseOptions.android.apiKey +
            '&mode=' +
            travelModeUsuario +
            '&language=pt-BR');

    // Do busão até a parada
    var retBus = await Dio().get(
        'https://maps.googleapis.com/maps/api/distancematrix/json?destinations=' +
            posBusao.latitude.toString() +
            ',' +
            posBusao.longitude.toString() +
            '&origins=' +
            posParada.latitude.toString() +
            ',' +
            posParada.longitude.toString() +
            '&key=' +
            DefaultFirebaseOptions.android.apiKey +
            '&mode=' +
            travelModeBusao +
            '&language=pt-BR');
    parada.tempoChegadaUsuario =
        retUsu.data['rows'].first['elements'].first['duration']['text'];
    parada.tempoChegadaBusao =
        retBus.data['rows'].first['elements'].first['duration']['text'];
    parada.distanciaAteUsuario =
        retUsu.data['rows'].first['elements'].first['distance']['text'];
    parada.distanciaAteBusao =
        retBus.data['rows'].first['elements'].first['distance']['text'];
    parada.latitude = posParada.latitude;
    parada.longitude = posParada.longitude;
    return parada;
  }

  Future<LatLng?> buscaParadaProxima(LatLng pos) async {
    double distanciaMin = 100000;
    double distanciaHaversine = 0;
    LatLng? markerPosition;
    // Busca a parada mais próxima da rota atual.
    for (var i = 0; i < rotaAtual.parada.length - 1; i++) {
      distanciaHaversine = Haversine.haversine(
        pos.latitude,
        pos.longitude,
        rotaAtual.parada[i].latitude,
        rotaAtual.parada[i].longitude,
      );
      if (distanciaHaversine < distanciaMin) {
        distanciaMin = distanciaHaversine;
        markerPosition = LatLng(
          rotaAtual.parada[i].latitude,
          rotaAtual.parada[i].longitude,
        );
      }
    }
    return markerPosition;
  }

  void limpaMarcacoes() {
    markers.clear();
    polylines.clear();
  }
}
