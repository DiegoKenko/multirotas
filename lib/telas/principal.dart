import 'package:flutter/material.dart';
import 'package:multirotas/telas/mapa.dart';
import 'listaRotas.dart';

class Principal extends StatefulWidget {
  Principal({Key? key}) : super(key: key);

  @override
  State<Principal> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TelaMapa()),
                  );
                },
                child: Text("Minha Rota"),
              ),
              height: 80,
            ),
            SizedBox(
              height: 80,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ListaRotas()),
                  );
                },
                child: Text('Bucar Rota'),

              ),
            )
          ],
        ),
      ),
    );
  }
}
