import 'package:cabinet_ble_test/scan_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
       
        primarySwatch: Colors.blue,
      ),
      home:const ScanPage() ,
    );
  }
}

