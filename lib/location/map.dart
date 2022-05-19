import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
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
  double raioBuscaMetro = 1000;
  bool cameraDinamica = true;
  bool mostraRotaAtual = false;
  bool ida = true;
  bool visualizaRotas = false;
  StreamSubscription<Position>? _currentPosition;
  final Geolocator geo = Geolocator();
  CameraPosition _initialLocation = const CameraPosition(
    target: LatLng(-19.49392296505924, -44.30632263820034), // Multitécnica
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
              ]),
            ),
          ),
          elevation: 2,
          backgroundColor: Colors.transparent,
        ),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        ),
        body: Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            GoogleMap(
              markers: Set<Marker>.from(markers),

              //mapToolbarEnabled: true,
              compassEnabled: true,
              polylines: Set<Polyline>.of(polylines.values),
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
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
                            'nome da rota',
                            style: TextStyle(fontSize: 30),
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
                      color: cameraDinamica ? Color(0xFF57C0A4) : Colors.grey,
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
      _rotasProximas();
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
      color: const Color(0xFF40683E),
      points: polylineCoordinates,
      width: 3,
    );

    // Adding the polyline to the map
    return polyline;
  }

  // Atualização stream da localização dos ônibus
  // Os ônibus são identificados como marcadores
  _getRotas() async {
    todasRotas = await Firestore().todasRotas();
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

  Future<void> _rotasProximas() async {
    Set<Marker> tempMarker = {};
    List<Rota> rotasProximas = await Firestore().rotasProximas(
        double.parse(_initialLocation.target.latitude.toString()),
        double.parse(_initialLocation.target.longitude.toString()),
        raioBuscaMetro / 1000);
    for (var i = 0; i < rotasProximas.length; i++) {
      for (var j = 0; j < rotasProximas[i].parada.length; j++) {
        final rotaTemp = rotasProximas[i];
        Marker markTemp = Marker(
          zIndex: i * 10.0 + j,
          onTap: () {
            setState(() {
              visualizaRotas = false;
              montaPolyline(todasRotas
                  .firstWhere((element) => (element.id == rotaTemp.id)));
              mostraRotaAtual = true;
            });
          },
          markerId: MarkerId(rotasProximas[i].nome + '|' + j.toString()),
          position: LatLng(rotasProximas[i].parada[j].latitude,
              rotasProximas[i].parada[j].longitude),
          infoWindow: InfoWindow(
            title: rotasProximas[i].nome,
            snippet: rotasProximas[i].id,
          ),
          icon: BitmapDescriptor.defaultMarker,
        );
        tempMarker.add(markTemp);
      }
    }
    setState(() {
      markers.clear();
      markers = tempMarker;
    });
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
        rotaAtual = rota;
        polylines.clear();
        setState(
          () {
            polylines[value.polylineId] = value;
          },
        );
      },
    );
  }
}
