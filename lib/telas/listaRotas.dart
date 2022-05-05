import 'package:flutter/material.dart';

class ListaRotas extends StatefulWidget {
  ListaRotas({Key? key}) : super(key: key);

  @override
  State<ListaRotas> createState() => _ListaRotasState();
}

class _ListaRotasState extends State<ListaRotas> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      padding: EdgeInsets.only(top: 70, left: 20, right: 20),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Destino...',
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
        ),
      ),
    ));
  }
}
