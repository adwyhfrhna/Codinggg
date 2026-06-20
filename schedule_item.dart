import 'package:flutter/material.dart';

class ScheduleItem extends StatefulWidget {
  final Map<String, Map<int, Map<String, String>>> initialTable;

  const ScheduleItem({Key? key, this.initialTable = const {}}) : super(key: key);

  @override
  _ScheduleItemState createState() => _ScheduleItemState();
}

class _ScheduleItemState extends State<ScheduleItem> {
  Map<String, Map<int, Map<String, String>>> tempTable = {};
  final days = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
  final rows = List.generate(7, (i) => i);

  @override
  void initState() {
    super.initState();
    tempTable = Map.from(widget.initialTable.map((key, value) => 
      MapEntry(key, Map<int, Map<String, String>>.from(value))
    ));
  }

  Future<void> _addItem(String day, int row) async {
    final titleCtrl = TextEditingController();
    final venueCtrl = TextEditingController();
    TimeOfDay? startTime;
    int durationHours = 1;
    int durationMinutes = 0;

    bool isEditing = tempTable[day]?[row] != null;

    if (isEditing) {
      final currentData = tempTable[day]![row]!;
      titleCtrl.text = currentData['title'] ?? "";
      venueCtrl.text = currentData['venue'] ?? "";
      try {
        final timeParts = currentData['startTime']!.split(':');
        startTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
      } catch (_) {}
    }

    String _formatTime(TimeOfDay t) =>
        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

    TimeOfDay _calculateEndTime(TimeOfDay start, int hours, int minutes) {
      final totalMinutes = start.hour * 60 + start.minute + (hours * 60) + minutes;
      final endHour = (totalMinutes ~/ 60) % 24;
      final endMinute = totalMinutes % 60;
      return TimeOfDay(hour: endHour, minute: endMinute);
    }

    var result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? "Edit Class for $day" : "Add Class for $day"),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: InputDecoration(labelText: "Title")),
                  TextField(controller: venueCtrl, decoration: InputDecoration(labelText: "Venue")),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    child: Text(startTime == null
                        ? "Pick Start Time"
                        : "Start: ${_formatTime(startTime!)}"),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => startTime = picked);
                      }
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(labelText: "Duration Hours"),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => durationHours = int.tryParse(val) ?? 0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(labelText: "Duration Minutes"),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => durationMinutes = int.tryParse(val) ?? 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          if (isEditing)
            TextButton(
              onPressed: () => Navigator.pop(context, {"action": "delete"}),
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(context, null), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (startTime != null) {
                final endTime = _calculateEndTime(startTime!, durationHours, durationMinutes);
                Navigator.pop(context, {
                  "action": "save",
                  "data": {
                    "day": day,
                    "row": row.toString(),
                    "title": titleCtrl.text,
                    "venue": venueCtrl.text,
                    "startTime": _formatTime(startTime!),
                    "endTime": _formatTime(endTime),
                  }
                });
              }
            },
            child: Text("OK"),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        if (result["action"] == "delete") {
          tempTable[day]?.remove(row);
        } else if (result["action"] == "save") {
          tempTable[day] ??= {};
          tempTable[day]![row] = Map<String, String>.from(result["data"]);
        }
      });
    }
  }

  void _saveAll() {
    Navigator.pop(context, tempTable);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // MATCHED DESIGN: Fullscreen background image
          Positioned.fill(
            child: Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 50, bottom: 10, right: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context, null),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Add Schedules",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 30),
                  child: Column(
                    children: [
                      Expanded(
                        child: Table(
                          border: TableBorder.all(color: Colors.transparent),
                          children: [
                            TableRow(
                              children: days.map((d) => Container(
                                padding: const EdgeInsets.only(bottom: 12),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.black26, width: 1)),
                                ),
                                child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold))),
                              )).toList(),
                            ),
                            ...rows.map((slot) {
                              return TableRow(
                                children: days.map((day) {
                                  final cellData = tempTable[day]?[slot];
                                  return GestureDetector(
                                    onTap: () => _addItem(day, slot),
                                    child: Container(
                                      margin: const EdgeInsets.all(1),
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 241, 213, 246),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: cellData == null
                                            ? const Icon(Icons.add)
                                            : Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(cellData['title'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  Text(cellData['venue'] ?? "", style: const TextStyle(fontSize: 8)),
                                                  Text("${cellData['startTime']} - ${cellData['endTime']}", style: const TextStyle(fontSize: 8)),
                                                ],
                                              ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: ElevatedButton.icon(
                          onPressed: _saveAll,
                          icon: const Icon(Icons.save),
                          label: const Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}