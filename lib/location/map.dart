import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  var posicaoUsuario;
  var posicaoBusao;
  CameraPosition _initialLocation =
      CameraPosition(target: LatLng(-19.4948441, -44.3076397), zoom: 15);
  late GoogleMapController mapController;
  final startAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  _getCurrentLocation() {
    // Atualização da localização
    // É possível utilizar 'await Geolocator.getCurrentPosition'

    Geolocator.getPositionStream(
            desiredAccuracy: LocationAccuracy.medium,
            intervalDuration: Duration(seconds: 10))
        .listen((position) {
      posicaoUsuario = position;
      _initialLocation = CameraPosition(
          target: LatLng(posicaoUsuario.latitude, posicaoUsuario.longitude));
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return SizedBox(
      height: height,
      width: width,
      child: Scaffold(
        appBar: AppBar(),
        body: Stack(children: [
          GoogleMap(
            initialCameraPosition: _initialLocation,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
          ),
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: ClipOval(
              child: Material(
                color: Colors.white, // button color
                child: InkWell(
                  splashColor: Colors.blue, // inkwell color
                  child: const SizedBox(
                    width: 60,
                    height: 60,
                    child: Icon(Icons.my_location),
                  ),
                  onTap: () {},
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
