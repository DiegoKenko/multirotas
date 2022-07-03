import 'dart:async' show StreamSubscription;
import 'dart:convert' show utf8;
import 'package:firebase_database/firebase_database.dart'
    show DatabaseEvent, DatabaseReference, FirebaseDatabase;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter_polyline_points/flutter_polyline_points.dart'
    show
        PolylinePoints,
        PolylineWayPoint,
        PointLatLng,
        PolylineResult,
        TravelMode;
import 'package:geocoding/geocoding.dart'
    show Location, Placemark, locationFromAddress, placemarkFromCoordinates;
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show
        CameraPosition,
        LatLng,
        GoogleMap,
        GoogleMapController,
        PolylineId,
        Polyline,
        Marker,
        Circle,
        MarkerId,
        MapType,
        BitmapDescriptor,
        CameraUpdate,
        InfoWindow,
        CircleId;
import 'package:geolocator/geolocator.dart'
    show Position, Geolocator, LocationAccuracy;
import 'package:multirotas/class/busao_class.dart';
import 'package:multirotas/class/rota_class.dart';
import 'package:multirotas/firebase/firestore.dart' show Firestore;
import 'package:dio/dio.dart' show Dio;
import 'package:multirotas/firebase_options.dart' show DefaultFirebaseOptions;
import 'package:multirotas/location/haversine.dart';
import 'package:multirotas/class/parada_class.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final Color rotaColor = const Color.fromARGB(255, 51, 197, 241);
  final Color busaoColor = const Color.fromARGB(255, 0, 102, 255);
  final Color usuarioColor = const Color.fromARGB(106, 19, 232, 0);
  static const double latMulti = -19.49392296505924;
  static const double longMult = -44.30632263820034;
  double raioBuscaMetro = 600;
  bool normalMap = true;
  bool cameraDinamica = false;
  bool mostraRotaAtual = false;
  bool mostraParadaAtual = false;
  bool mostraBusaoAtual = false;
  bool ida = true;
  bool mapTapAllowed = false;
  StreamSubscription<Position>? _currentPositionStream;
  StreamSubscription<DatabaseEvent>? _currentPositionStreamBusao;
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
  Rota rotaAtual = Rota();
  Busao busaoAtual = Busao();
  Parada paradaAtual = Parada();
  Marker markerM = const Marker(markerId: MarkerId('mt'), visible: false);
  Marker markersBusao =
      const Marker(markerId: MarkerId('busao'), visible: false);
  TextEditingController buscaControllerDestino = TextEditingController();
  int contadorAttDetalhes = 0;

  @override
  void initState() {
    super.initState();
    _getStremLocation(); // Att localização do usuário
    markerMulti(); // Att marcador
    // Busca todas ritas
    getRotas(); // Deve ser executado depois do _getStremLocation
  }

  @override
  void dispose() {
    _currentPositionStream?.cancel();
    _currentPositionStream = null;
    _currentPositionStreamBusao?.cancel();
    _currentPositionStreamBusao = null;
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
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          drawerScrimColor: const Color.fromARGB(144, 0, 0, 0),
          drawer: Drawer(
            elevation: 2,
            backgroundColor: const Color.fromARGB(255, 55, 61, 105),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
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
                            mostraRotaAtual = false;
                            mostraBusaoAtual = false;
                            mostraParadaAtual = false;
                            polylines.clear();
                            markers.clear();
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
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: FutureBuilder(
                            future: PackageInfo.fromPlatform(),
                            builder:
                                (context, AsyncSnapshot<PackageInfo> snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  'Versão ' + snapshot.data!.version,
                                  style: const TextStyle(
                                    color: Colors.yellow,
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
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
                            FocusScope.of(context)
                                .unfocus(); // esconder teclado
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
                  markers.add(markerM);
                },
                onTap: (pos) async {
                  if (mapTapAllowed && ida) {
                    // Busca parada mais próxima do toque.
                    LatLng? paradaLatLng = await buscaParadaProxima(pos);

                    // Adiciona as paradas para calcular o tempo/distância
                    List<LatLng> paradasCaminho = [];
                    bool parAntes = true;
                    int contAntes = 0;
                    // Somente será considerados as paradas anterior a parada atual
                    for (var element in rotaAtual.parada!) {
                      if (element.latitude == paradaLatLng!.latitude &&
                          element.longitude == paradaLatLng.longitude) {
                        parAntes = false;
                      }
                      if (parAntes && contAntes % 3 == 0) {
                        paradasCaminho
                            .add(LatLng(element.latitude!, element.longitude!));
                      }
                      contAntes++;
                    }

                    var iconMarkerParada =
                        await BitmapDescriptor.fromAssetImage(
                            const ImageConfiguration(size: Size(100, 100)),
                            "assets/paradaMap.png");

                    // Busca tempo/distância.
                    Parada paradaAtualTemp;
                    paradaAtualTemp = await detalhesParada(
                      destino: LatLng(
                          paradaLatLng!.latitude, paradaLatLng.longitude),
                      wayPoints: paradasCaminho,
                      posBusao:
                          LatLng(busaoAtual.latitude!, busaoAtual.longitude!),
                    );

                    if (paradaAtual != paradaAtualTemp) {
                      setState(
                        () {
                          paradaAtual = paradaAtualTemp;
                          mostraParadaAtual = true;
                          // reseta marcadores
                          //limpaMarcacoes();

                          markers.add(
                            Marker(
                              anchor: const Offset(0.5, 0.5),
                              markerId: const MarkerId("nearestMarker"),
                              position: paradaLatLng,
                              icon: iconMarkerParada,
                            ),
                          );
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
                                      rotaAtual.nome!,
                                      style: const TextStyle(fontSize: 30),
                                    ),
                                  ),
                                  mostraParadaAtual
                                      ? Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                              paradaAtual.thoroughfare! +
                                                  ', ' +
                                                  paradaAtual.subThoroughfare!),
                                        )
                                      : const Text(''),
                                ],
                              ),
                              trailing: IconButton(
                                onPressed: () {
                                  setState(() {
                                    polylines.clear();
                                    markers.removeWhere((element) =>
                                        element.markerId.value ==
                                        'nearestMarker');
                                    markers.removeWhere((element) =>
                                        element.markerId.value == 'busao');
                                    mostraRotaAtual = false;
                                    mapTapAllowed = false;
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
                                      child: Icon(Icons.directions_bus_rounded),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(
                                          top: 8, bottom: 8, left: 8),
                                      child: Text(' A '),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8,
                                        bottom: 8,
                                      ),
                                      child: Text(
                                        paradaAtual.tempoChegadaBusao
                                            .toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: busaoColor,
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets.only(top: 8, bottom: 8),
                                      child: Text(' e '),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 8, bottom: 8),
                                      child: Text(
                                        paradaAtual.distanciaAteBusao
                                            .toString(),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: busaoColor),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(
                                        top: 8,
                                        bottom: 8,
                                      ),
                                      child:
                                          Text(' até a parada selecionada. '),
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
                              return Card(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(left: 5, right: 5),
                                  child: Center(
                                    child: Text(
                                      'Rotas:'.toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF373D69),
                                        letterSpacing: 3,
                                      ),
                                    ),
                                  ),
                                ),
                                shadowColor: Colors.white,
                                color: const Color.fromARGB(255, 240, 224, 4),
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
      ),
    );
  }

  // Busca todas rotas disponíveis.
  getRotas() async {
    todasRotas = await Firestore().todasRotas();
  }

  // Atualização da localização como stream.
  _getStremLocation() async {
    // Busca a localização atual ao iniciar o App.
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

    // Busca localização como stream.
    _currentPositionStream = Geolocator.getPositionStream(
      intervalDuration: const Duration(seconds: 5),
      desiredAccuracy: LocationAccuracy.high,
    ).listen(
      (event) {
        //Mudança do local.
        _initialLocation = CameraPosition(
          target: LatLng(
            event.latitude,
            event.longitude,
          ),
        );

        // Mudança do foco da câmera.
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

        //
        if (ida) {
          // Atualiza rotas próximas
          _rotasProximasIda();

          if (mostraBusaoAtual && mostraParadaAtual && mostraRotaAtual) {}
          setState(
            () {
              attCircle(LatLng(_initialLocation.target.latitude,
                  _initialLocation.target.longitude));
            },
          );
        }
      },
    );
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
              rota.nome!.toUpperCase(),
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
          if (ida || rota.parada!.isNotEmpty) {
            mostraParadaAtual = false;
            mapTapAllowed = true;
            // Busca todos dados da rota.
            rotaAtual = todasRotas.firstWhere(
              (element) => (element.id == rota.id),
            );

            //Recebe localização do busão como stream.
            _getStremRealtimeBusao(rotaAtual);
            mostraRotaAtual = true;

            // Atualiza markers e polylines
            polylines.clear();
            markers.removeWhere((element) => element.markerId.value == 'busao');
            markers.removeWhere(
                (element) => element.markerId.value == 'nearestMarker');
            montaPolyline(rotaAtual);
          }
        },
      ),
    );
  }

  // Busca as rotas próximas de acordo com a localização do usuário.
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

  // Atualiza marcador que indica a localização da Multitécnica.
  void markerMulti() async {
    var iconMarkerMulti = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(100, 100)), "assets/mtMap.png");
    markerM = Marker(
      markerId: const MarkerId('mt'),
      position: const LatLng(latMulti, longMult),
      infoWindow: const InfoWindow(
        title: 'Grupo Multitécnica',
      ),
      icon: iconMarkerMulti,
    );
  }

  // Atualiza posição visual do raio de busca.
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
    for (var i = 0; i < rota.parada!.length - 1; i++) {
      wayPoints.add(
        PolylineWayPoint(
          location: rota.parada![i].latitude.toString() +
              ',' +
              rota.parada![i].longitude.toString(),
        ),
      );
    }
    _createPolylines(
            rota.parada![0].latitude!,
            rota.parada![0].longitude!,
            ida ? latMulti : rota.parada![rota.parada!.length - 1].latitude!,
            ida ? longMult : rota.parada![rota.parada!.length - 1].longitude!,
            rota.nome!,
            wayPoints,
            rotaColor,
            7)
        .then(
      (value) {
        setState(
          () {
            //(polyline: true, busaoStream: true);
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
      polylines.clear();
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
      for (var j = 0; j < rotasProximas[i].parada!.length; j++) {
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
          markerId: MarkerId(rotasProximas[i].nome! + '|' + j.toString()),
          position: LatLng(rotasProximas[i].parada![j].latitude!,
              rotasProximas[i].parada![j].longitude!),
          infoWindow: InfoWindow(
            title: rotasProximas[i].nome,
            snippet: rotasProximas[i].parada![j].latitude.toString() +
                ' | ' +
                rotasProximas[i].parada![j].longitude.toString(),
          ),
          icon: iconMarkerParada,
        );
        tempMarker.add(markTemp);
      }
    }
    setState(() {
      tempMarker.add(markerM);
      tempMarker.add(markerDestino);
      markers = tempMarker;
    });
  }

  listaDeParadas(Rota rota) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            rota.parada![index].nome!,
            style: const TextStyle(fontSize: 18),
          ),
          subtitle: Text(
            rota.parada![index].latitude.toString() +
                ' | ' +
                rota.parada![index].longitude.toString(),
            style: const TextStyle(fontSize: 14),
          ),
        );
      },
      itemCount: rota.parada!.length,
    );
  }

  Future<Parada> detalhesParada({
    required LatLng destino,
    required List<LatLng> wayPoints,
    required LatLng posBusao,
  }) async {
    String travelModeBusao = "driving";
    String wPointString = '';
    Parada parada = Parada();
    List<Placemark> lugares = await placemarkFromCoordinates(
        wayPoints.first.latitude, wayPoints.first.longitude);
    parada.thoroughfare = lugares.first.thoroughfare;
    parada.subThoroughfare = lugares.first.subThoroughfare;

    for (var i = 0; i < wayPoints.length - 1; i++) {
      wPointString += 'via:';
      wPointString += wayPoints[i].latitude.toString();
      wPointString += ',';
      wPointString += wayPoints[i].longitude.toString();
    }
    // Do busão até a parada
    var retBus = await Dio().get(
        'https://maps.googleapis.com/maps/api/distancematrix/json?destinations=' +
            destino.latitude.toString() +
            ',' +
            destino.longitude.toString() +
            '&origins=' +
            posBusao.latitude.toString() +
            ',' +
            posBusao.longitude.toString() +
            '&waypoints=' +
            wPointString +
            '&key=' +
            DefaultFirebaseOptions.android.apiKey +
            '&mode=' +
            travelModeBusao +
            '&language=pt-BR');

    parada.tempoChegadaBusao =
        retBus.data['rows'].first['elements'].first['duration']['text'];
    parada.distanciaAteBusao =
        retBus.data['rows'].first['elements'].first['distance']['text'];
    parada.latitude = destino.latitude;
    parada.longitude = destino.longitude;
    return parada;
  }

  Future<LatLng?> buscaParadaProxima(LatLng pos) async {
    double distanciaMin = 100000;
    double distanciaHaversine = 0;
    LatLng? markerPosition;
    // Busca a parada mais próxima da rota atual.
    for (var i = 0; i < rotaAtual.parada!.length - 1; i++) {
      distanciaHaversine = Haversine.haversine(
        pos.latitude,
        pos.longitude,
        rotaAtual.parada![i].latitude,
        rotaAtual.parada![i].longitude,
      );
      if (distanciaHaversine < distanciaMin) {
        distanciaMin = distanciaHaversine;
        markerPosition = LatLng(
          rotaAtual.parada![i].latitude!,
          rotaAtual.parada![i].longitude!,
        );
      }
    }
    return markerPosition;
  }

  _getStremRealtimeBusao(Rota rota) {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref('localizacaoBusao/' + rota.id!);
    _currentPositionStreamBusao = null;
    _currentPositionStreamBusao =
        ref.onValue.listen((DatabaseEvent event) async {
      Map<dynamic, dynamic> tempBusao =
          event.snapshot.value as Map<dynamic, dynamic>;
      busaoAtual = Busao.fromMap(tempBusao);

      var iconMarkerBusao = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(
            size: Size(100, 100),
          ),
          "assets/busao.png");
      if (mapTapAllowed && mostraParadaAtual && ida) {
        // A atualização do tempo/distância do busão é feita apenas a cada 6 atualizações de localização do busão.
        contadorAttDetalhes++;
        if (contadorAttDetalhes % 4 == 0) {
          // Adiciona as paradas para calcular o tempo/distância
          List<LatLng> paradasCaminho = [];
          bool parAntes = true;
          int contAntes = 0;
          // Somente será considerados as paradas posteriores a parada atual
          for (var element in rotaAtual.parada!) {
            if (element.latitude == paradaAtual.latitude &&
                element.longitude == paradaAtual.longitude) {
              parAntes = false;
            }
            if (parAntes && contAntes % 3 == 0) {
              paradasCaminho.add(LatLng(element.latitude!, element.longitude!));
            }
            contAntes++;
          }

          // Busca temo/distância
          Parada paradaAtualTemp;
          paradaAtualTemp = await detalhesParada(
            destino: LatLng(paradaAtual.latitude!, paradaAtual.longitude!),
            wayPoints: paradasCaminho,
            posBusao: LatLng(busaoAtual.latitude!, busaoAtual.longitude!),
          );
          setState(() {
            paradaAtual = paradaAtualTemp;
          });
        }
      }

      markers.add(Marker(
        rotation: busaoAtual.heading! <= 90
            ? busaoAtual.heading! - 90
            : busaoAtual.heading! - 90 + 360,
        markerId: const MarkerId('busao'),
        icon: iconMarkerBusao,
        position: LatLng(busaoAtual.latitude!, busaoAtual.longitude!),
      ));
    });
  }
}
