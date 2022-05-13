import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:multirotas/firebase/firestore.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  CameraPosition _initialLocation =
      const CameraPosition(target: LatLng(-19.4948441, -44.3076397), zoom: 15);
  late GoogleMapController mapController;
  late PolylinePoints polylinePoints;
  List<LatLng> polylineCoordinates = [];
  final startAddressController = TextEditingController();
  Map<PolylineId, Polyline> polylines = {};

  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _getStremLocation();
    //_getRotas();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return SizedBox(
      height: height,
      width: width,
      child: Scaffold(
        body: Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            GoogleMap(
              markers: Set<Marker>.from(markers),
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
            Positioned(
              child: Container(
                child: Center(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      SizedBox(
                        width: 220,
                        height: 80,
                        child: Card(
                          color: Color(0xFF373D69),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        height: 80,
                        child: Card(
                          color: Color(0xFF373D69),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        height: 80,
                        child: Card(
                          color: Color(0xFF373D69),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        height: 80,
                        child: Card(
                          color: Color(0xFF373D69),
                        ),
                      ),
                    ],
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 5),
                height: 120,
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
    Geolocator.getPositionStream(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      intervalDuration: const Duration(seconds: 2),
    ).listen(
      (position) {
        _initialLocation = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
        );
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15.0,
            ),
          ),
        );
      },
    );
  }

  _createPolylines(
      double startLatitude,
      double startLongitude,
      double destinationLatitude,
      double destinationLongitude,
      String nomeId) async {
    // Initializing PolylinePoints
    polylinePoints = PolylinePoints();

    // Generating the list of coordinates to be used for
    // drawing the polylines
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyC-cAQ95icIXxAelzKYLjwVVDCw-KFmuBw', // Google Maps API Key
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.transit,
    );

    // Adding the coordinates to the list
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

    // Defining an ID
    PolylineId id = PolylineId(nomeId);

    // Initializing Polyline
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );

    // Adding the polyline to the map
    polylines[id] = polyline;
  }

  // Atualização stream da localização dos ônibus
  // Os ônibus são identificados como marcadores
  void _getBusaoLocation() async {
    var rotas = await Firestore().todasRotas();
    // Deve buscar as rotas e seu repectivo busao.
    for (var element in rotas) {}
  }
}
