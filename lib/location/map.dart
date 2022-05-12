import 'dart:async';

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
  final startAddressController = TextEditingController();

  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _getBusaoLocation();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return SizedBox(
      height: height,
      width: width,
      child: Scaffold(
        body: Stack(children: [
          GoogleMap(
            markers: Set<Marker>.from(markers),
            compassEnabled: true,
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
            bottom: 20,
            right: 20,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: ClipOval(
                child: Material(
                  color: Colors.white,
                  child: InkWell(
                    splashColor: Colors.blue,
                    child: const SizedBox(
                      width: 60,
                      height: 60,
                      child: Icon(Icons.my_location),
                    ),
                    onTap: () {
                      _getCurrentLocation();
                    },
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // Atualização da localização como stream.
  // É possível utilizar 'await Geolocator.getCurrentPosition'
  _getCurrentLocation() async {
    bool _ativo = await Geolocator.isLocationServiceEnabled();
    if (!_ativo) {
      await Geolocator.getCurrentPosition();
    }
    Geolocator.getPositionStream(
      desiredAccuracy: LocationAccuracy.best,
      intervalDuration: const Duration(seconds: 2),
      distanceFilter: 10,
    ).listen(
      (position) {
        _initialLocation = CameraPosition(
            target: LatLng(position.latitude, position.longitude));
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              tilt: 0,
              bearing: 0,
              zoom: 15.0,
            ),
          ),
        );
      },
    );
  }

  // Atualização stream da localização dos ônibus
  // Os ônibus são identificados como marcadores
  void _getBusaoLocation() async {
    var rotas = await Firestore().todasRotas();
    // Deve buscar as rotas e seu repectivo busao.
    rotas.forEach((element) {});
  }
}
