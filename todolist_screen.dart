import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/task_item.dart';

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final CollectionReference tasksRef =
      FirebaseFirestore.instance.collection('tasks');

  String _selectedFilter = "All";

  String _calculatePriority(DateTime deadline) {
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    if (daysLeft < 3) return "High";
    if (daysLeft < 7) return "Medium";
    return "Low";
  }

  Color _getDayColor(DateTime day, List<QueryDocumentSnapshot> docs) {
    final dayTasks = docs.where((doc) {
      final dt = (doc['dateTime'] as Timestamp).toDate();
      return dt.year == day.year && dt.month == day.month && dt.day == day.day;
    }).toList();

    if (dayTasks.isEmpty) return Colors.transparent;

    int minDaysLeft = dayTasks.map((doc) {
      final dt = (doc['dateTime'] as Timestamp).toDate();
      return dt.difference(DateTime.now()).inDays;
    }).reduce((a, b) => a < b ? a : b);

    if (minDaysLeft < 3) return Colors.redAccent;
    if (minDaysLeft < 7) return Colors.orangeAccent;
    return Colors.green;
  }

  void _addTask(String title, String note, DateTime dateTime) {
    final priority = _calculatePriority(dateTime);
    tasksRef.add({
      'title': title,
      'note': note,
      'dateTime': dateTime,
      'priority': priority,
      'completed': false,
    });
  }

  void _deleteTask(String id) => tasksRef.doc(id).delete();
  void _toggleComplete(String id, bool current) =>
      tasksRef.doc(id).update({'completed': !current});

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Task"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: "Note")),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2025, 1, 1),
                  lastDate: DateTime(2027, 12, 31),
                );
                if (picked != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedDate),
                  );
                  if (time != null) {
                    selectedDate = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      time.hour,
                      time.minute,
                    );
                  }
                }
              },
              child: const Text("Pick Date & Time"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                _addTask(titleController.text, noteController.text, selectedDate);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(DocumentSnapshot doc) {
    final taskData = doc.data() as Map<String, dynamic>;
    final titleController = TextEditingController(text: taskData['title']);
    final noteController = TextEditingController(text: taskData['note']);
    DateTime selectedDate = (taskData['dateTime'] as Timestamp).toDate();
    bool completed = taskData['completed'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Task"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: "Note")),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2025, 1, 1),
                  lastDate: DateTime(2027, 12, 31),
                );
                if (picked != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedDate),
                  );
                  if (time != null) {
                    selectedDate = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      time.hour,
                      time.minute,
                    );
                  }
                }
              },
              child: const Text("Pick Date & Time"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final priority = _calculatePriority(selectedDate);
              tasksRef.doc(doc.id).update({
                'title': titleController.text,
                'note': noteController.text,
                'dateTime': selectedDate,
                'priority': priority,
                'completed': completed,
              });
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg.png"), // wallpaper
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("To-Do List", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 30, color: Color.fromARGB(255, 4, 24, 60)),
                  onPressed: () => _showAddTaskDialog(), // Add Task button di atas
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: tasksRef.snapshots(),
                builder: (ctx, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;

                  return Column(
                    children: [
                      Flexible(
                        child: TableCalendar(
                          firstDay: DateTime(2025, 1, 1),
                          lastDay: DateTime(2027, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          daysOfWeekVisible: false, // buang tulisan "2 weeks"
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) {
                              final color = _getDayColor(day, docs);
                              return Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: color == Colors.transparent ? null : color.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(child: Text("${day.day}")),
                              );
                            },
                          ),
                          calendarStyle: const CalendarStyle(
                            todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                            selectedDecoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text("Tasks", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () => setState(() => _selectedFilter = "High"),
                            child: const Text("High"),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                            onPressed: () => setState(() => _selectedFilter = "Medium"),
                            child: const Text("Medium"),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () => setState(() => _selectedFilter = "Low"),
                            child: const Text("Low"),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                            onPressed: () => setState(() => _selectedFilter = "All"),
                            child: const Text("All"),
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListView(
                          children: docs.where((doc) {
                            if (_selectedFilter == "All") return true;
                            return doc['priority'] == _selectedFilter;
                          }).map((doc) {
                            final taskData = doc.data() as Map<String, dynamic>;
                            return TaskItem(
                              task: taskData,
                              onEdit: () => _showEditTaskDialog(doc),
                              onDelete: () => _deleteTask(doc.id),
                              onToggleComplete: () => _toggleComplete(doc.id, taskData['completed']),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}