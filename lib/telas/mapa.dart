import 'package:flutter/material.dart';
import 'package:multirotas/location/map.dart';

class TelaMapa extends StatelessWidget {
  const TelaMapa({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          MapView(),
        ],
      ),
    );
  }
}
