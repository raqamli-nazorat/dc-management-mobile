import 'package:flutter/material.dart';
import 'package:dcmanagement/models/worker_model.dart';

class WorkerCard extends StatelessWidget {
  final WorkerModel worker;

  const WorkerCard({super.key, required this.worker});

  String get _initials {
    final parts = worker.name.split(' ');
    return parts.take(2).map((p) => p[0]).join();
  }

  String _formatMoney(double amount) {
    // 12000000 → "12 000 000,00"
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[0]} ',
    );
    return '$intPart,${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + name + checkmark
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Full name:  ${worker.name}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                        children: [
                          const TextSpan(text: "Position: "),
                          TextSpan(
                            text: worker.position,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Info rows
          _infoRow("Role:", worker.role),
          _infoRow("Salary:", "${_formatMoney(worker.salary)} so'm"),
          _infoRow("Balance:", "${_formatMoney(worker.balance)} so'm"),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(text: "$label "),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}