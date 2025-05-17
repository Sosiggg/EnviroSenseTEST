import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String message = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchMessage();
  }

  void fetchMessage() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/v1/hello/'));
    if (response.statusCode == 200) {
      setState(() {
        message = jsonDecode(response.body)['message'];
      });
    } else {
      setState(() {
        message = 'Error: ${response.statusCode}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: Center(child: Text(message))),
    );
  }
}
