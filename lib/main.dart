import 'package:flutter/material.dart';
import 'telas/principal.dart';

void main() {
  runApp(const MultiRotas());
}

class MultiRotas extends StatelessWidget {
  const MultiRotas({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MultiRotas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TelaLogin(title: 'MultiRotas'),
    );
  }
}

class TelaLogin extends StatefulWidget {
  const TelaLogin({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<TelaLogin> createState() => TelaLoginState();
}

class TelaLoginState extends State<TelaLogin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text("Autenticação"),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            height: 250,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20, bottom: 20, top: 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'CPF',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.0),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20, bottom: 20),
            child: TextField(
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Senha',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.0),
                ),
              ),
            ),
          ),
          Container(
            width: 150,
            child: ElevatedButton(
              child: const Text('ENTRAR', style: TextStyle(fontSize: 17)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Principal()),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
