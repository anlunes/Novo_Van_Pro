import 'package:flutter/material.dart';

import 'basic_auth_gate.dart';

class BasicAuthApp extends StatelessWidget {
  const BasicAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Basic Auth',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const BasicAuthGate(),
    );
  }
}
