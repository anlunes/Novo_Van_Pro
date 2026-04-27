import 'package:flutter/material.dart';

class PaisScreen extends StatelessWidget {
  const PaisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Responsável')),
      body: const Center(
        child: Text('Tela do responsável'),
      ),
    );
  }
}