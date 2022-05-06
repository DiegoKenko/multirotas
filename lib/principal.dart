import 'package:flutter/material.dart';
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
                onPressed: () {},
                child: Text("minha rota"),
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
                child: Text('buscar rota'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
