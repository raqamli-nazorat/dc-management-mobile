import 'package:dcmanagement/api/firebase_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? token;
  final firebaseApi = FirebaseApi();

  @override
  void initState() {
    super.initState();
    loadToken();
  }

  Future<void> loadToken() async {
    final t = await firebaseApi.initNotfications();
    setState(() {
      token = t;
    });
  }

  void copyToken() {
    if (token != null) {
      Clipboard.setData(ClipboardData(text: token!));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token copied 🚀")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FCM Token")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SelectableText(
              token ?? "Loading...",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: copyToken,
              child: const Text("Copy Token"),
            ),
          ],
        ),
      ),
    );
  }
}