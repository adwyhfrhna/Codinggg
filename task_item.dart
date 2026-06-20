import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskItem extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;

  const TaskItem({
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
  });

  Color _priorityColor(String priority) {
    switch (priority) {
      case "High": return Colors.redAccent;
      case "Medium": return Colors.orangeAccent;
      case "Low": return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deadline = (task['dateTime'] as Timestamp).toDate();
    final formattedDate = DateFormat('dd/MM/yyyy | hh:mm a').format(deadline);
    final daysLeft = deadline.difference(DateTime.now()).inDays;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tajuk + Priority badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  task['title'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: task['completed'] ? TextDecoration.lineThrough : null,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _priorityColor(task['priority']),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task['priority'],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Nota tugasan
            if (task['note'] != null && task['note'].toString().isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.notes, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(task['note'])),
                ],
              ),

            const SizedBox(height: 4),

            // Tarikh + countdown hari
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text("$formattedDate  •  $daysLeft days left"),
              ],
            ),

            // Butang aksi
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    task['completed'] ? Icons.check_box : Icons.check_box_outline_blank,
                    color: Colors.green,
                  ),
                  onPressed: onToggleComplete,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
