import 'package:flutter/material.dart';
import 'package:dcmanagement/data/fake_workers.dart';
import 'package:dcmanagement/models/worker_model.dart';
import 'package:dcmanagement/widgets/worker_card.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<WorkerModel> _filtered = fakeWorkers;
  bool _searching = false;

  void _onSearch(String q) {
    final query = q.toLowerCase();
    setState(() {
      _filtered = fakeWorkers.where((w) =>
        w.name.toLowerCase().contains(query) ||
        w.role.toLowerCase().contains(query) ||
        w.position.toLowerCase().contains(query),
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text(
                    "Foydalanuvchilar",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _searching = !_searching),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Icon(Icons.search, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Search field
            if (_searching)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  autofocus: true,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: "Qidirish...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),

            // List
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) => WorkerCard(worker: _filtered[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}