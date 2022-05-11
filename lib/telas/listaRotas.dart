import 'package:flutter/material.dart';
import 'package:multirotas/firebase/firestore.dart';

class ListaRotas extends StatefulWidget {
  const ListaRotas({Key? key}) : super(key: key);

  @override
  State<ListaRotas> createState() => _ListaRotasState();
}

class _ListaRotasState extends State<ListaRotas> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(),
    );
  }

  _getTodasRotas() {
    Firestore().todasRotas();
  }
}
