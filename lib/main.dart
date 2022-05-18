import 'package:flutter/material.dart';
import 'package:multirotas/telas/mapa.dart';
import 'comp/decDegrade.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

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
    return FutureBuilder(
      future: Future.delayed(const Duration(seconds: 3)),
      builder: (context, s) {
        if (s.connectionState == ConnectionState.done) {
          return FutureBuilder(
            future: Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            ),
            builder: (context, snap) {
              return Scaffold(
                body: Container(
                  decoration: decDegrade(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(
                            left: 20.0, right: 20, bottom: 20, top: 0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'CPF',
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.white, width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.white, width: 1.0),
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding:
                            EdgeInsets.only(left: 20.0, right: 20, bottom: 20),
                        child: TextField(
                          obscureText: true,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: InputDecoration(
                            hintText: 'Senha',
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.white, width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.white, width: 1.0),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          style: const ButtonStyle(),
                          child: const Text('ENTRAR',
                              style: TextStyle(fontSize: 17)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const TelaMapa()),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return Scaffold(
            body: Container(
              decoration: decDegrade(),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Image.asset(
                      'lib/assets/carregamento.png',
                    ),
                    const Text(
                      'Carregando...',
                      style: TextStyle(fontSize: 22),
                    )
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
