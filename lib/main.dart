import 'package:flutter/material.dart';

import 'demo.dart';


void main() {
  //to avoid any crash
  //add ensureInitialized() before runApp()
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // This widget is the root of your application.

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Contacts Map',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //create a new class for this
      home: Demo(),
    );
  }
}