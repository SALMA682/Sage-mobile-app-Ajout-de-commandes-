import 'package:commande_clt/Connexion.dart';
import 'package:flutter/material.dart';
//import 'package:commande_clt/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Sage X3',
      debugShowCheckedModeBanner: false,
      home: VPNCheckPage(),
    );
  }
}
