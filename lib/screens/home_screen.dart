import 'package:flutter/material.dart';
import 'package:dcmanagement/services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bosh sahifa")),
      body: const Center(child: Text("Xush kelibsiz!")),
    );
  }
}
