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
      body: Center(
        child: Column(
          verticalDirection: VerticalDirection.down,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text("Rota1"),
                ),
                height: 60,
                width: 80,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text("Rota1"),
                ),
                height: 60,
                width: 80,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text("Rota1"),
                ),
                height: 60,
                width: 80,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text("Rota1"),
                ),
                height: 60,
                width: 80,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text("Rota1"),
                ),
                height: 60,
                width: 80,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text("Rota1"),
                ),
                height: 60,
                width: 80,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
