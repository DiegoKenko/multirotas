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
  CameraPosition _initialLocation = const CameraPosition(
    target: LatLng(-19.49392296505924, -44.30632263820034), // Multitécnica
    zoom: 16,
  );
  late GoogleMapController mapController;
  late PolylinePoints polylinePoints;
  final startAddressController = TextEditingController();
  Map<PolylineId, Polyline> polylines = {};
  List rotas = [];
  List rotasProximas = [];

  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _getStremLocation();
    _rotasProximas();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return SizedBox(
      height: height,
      width: width,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          actions: [],
        ),
        body: Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            GoogleMap(
              //markers: Set<Marker>.from(markers),
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
            ),
            Positioned.fill(
              bottom: 0,
              top: MediaQuery.of(context).size.height * 0.8,
              left: 0,
              right: 0,
              child: Container(
                child: FutureBuilder(
                  future: _getRotas(),
                  builder: (context, AsyncSnapshot snap) {
                    if (snap.hasData) {
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snap.data.length,
                        itemBuilder: (context, index) {
                          return cardRota(snap.data[index]);
                        },
                      );
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                ),
                margin: const EdgeInsets.only(bottom: 10),
                color: const Color(0xFF57C0A4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Atualização da localização como stream.
  // É possível utilizar 'await Geolocator.getCurrentPosition'
  _getStremLocation() async {
    Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).then(
      (position) {
        _initialLocation = CameraPosition(
          target: LatLng(
            position.latitude,
            position.longitude,
          ),
        );
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
                target: LatLng(
                  position.latitude,
                  position.longitude,
                ),
                zoom: 15),
          ),
        );
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
  Future<List> _getRotas() async {
    return await Firestore().todasRotas();
  }

  Widget cardRota(Rota rota) {
    List<PolylineWayPoint> wayPoints = [];
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      child: Card(
        elevation: 100,
        shadowColor: Colors.white,
        child: GestureDetector(
          onTap: () {
            wayPoints.clear();
            polylines.clear();
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
                setState(() {
                  polylines[value.polylineId] = value;
                  markers.add(
                    Marker(
                      markerId: MarkerId(rota.nome),
                      position: LatLng(
                        rota.parada[0].latitude,
                        rota.parada[0].longitude,
                      ),
                      infoWindow: InfoWindow(
                        title: rota.nome,
                      ),
                    ),
                  );
                });
              },
            );
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
    rotasProximas = await Firestore().rotasProximas(
      double.parse('-19.48563694104591'),
      double.parse(' -44.27729538359428'),
    );
  }
}
