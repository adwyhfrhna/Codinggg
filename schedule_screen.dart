import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'home_screen.dart'; 
import '../widgets/schedule_item.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final GlobalKey _globalKey = GlobalKey();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _downloadSchedule() async {
    try {
      RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/schedule.png');
      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Schedule saved to ${file.path}")),
      );
    } catch (e) {
      print(e);
    }
  }

  Future<void> _openScheduleItem() async {
    final uid = _auth.currentUser!.uid;
    
    final currentSnapshot = await _firestore
        .collection("users")
        .doc(uid)
        .collection("schedules")
        .get();

    Map<String, Map<int, Map<String, String>>> existingData = {};

    for (var doc in currentSnapshot.docs) {
      final data = doc.data();
      String day = data['day'] ?? '';
      int row = data['row'] ?? 0;

      existingData[day] ??= {};
      existingData[day]![row] = {
        "title": data['title'] ?? '',
        "venue": data['venue'] ?? '',
        "startTime": data['startTime'] ?? '',
        "endTime": data['endTime'] ?? '',
      };
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScheduleItem(initialTable: existingData)),
    );

    if (result != null) {
      for (var doc in currentSnapshot.docs) {
        await doc.reference.delete();
      }

      result.forEach((day, rows) {
        rows.forEach((row, data) async {
          await _firestore.collection("users").doc(uid).collection("schedules").add({
            "day": day,
            "row": row,
            "title": data["title"],
            "venue": data["venue"],
            "startTime": data["startTime"],
            "endTime": data["endTime"],
          });
        });
      });
    }
  }

  Widget _organizerContent() {
    final uid = _auth.currentUser!.uid;
    final days = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
    final rows = List.generate(7, (i) => i);

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/bg.png', fit: BoxFit.cover),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BAR ATAS: Sama sebiji macam susunan ScheduleItem!
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 50, bottom: 10, right: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Schedule Organizer",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.black),
                    onPressed: _openScheduleItem,
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
                      child: SingleChildScrollView(
                        // REPAINTBOUNDARY DAH DIALIKAN KE SINI (Hanya bungkus jadual sahaja)
                        child: RepaintBoundary(
                          key: _globalKey,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection("users")
                                .doc(uid)
                                .collection("schedules")
                                .orderBy("startTime")
                                .snapshots(),
                            builder: (context, snapshot) {
                              final docs = snapshot.hasData ? snapshot.data!.docs : [];

                              return Table(
                                border: TableBorder.all(color: Colors.transparent),
                                children: [
                                  TableRow(
                                    children: days.map((d) => Container(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: Colors.black26, width: 1),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    )).toList(),
                                  ),
                                  ...rows.map((slot) {
                                    return TableRow(
                                      children: days.map((day) {
                                        final matches = docs.where((doc) {
                                          final s = doc.data() as Map<String, dynamic>;
                                          return s['day'] == day && s['row'] == slot;
                                        }).toList();

                                        if (matches.isNotEmpty) {
                                          final s = matches.first.data() as Map<String, dynamic>;
                                          return _buildCell(s['title'], s['venue'], s['startTime'], s['endTime']);
                                        } else {
                                          return Container(
                                            margin: const EdgeInsets.all(1),
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: const ui.Color.fromARGB(255, 241, 213, 246),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          );
                                        }
                                      }).toList(),
                                    );
                                  }).toList(),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    // Butang download dinaikkan sikit (bottom: 40) bagi lawa
                    Padding(
                      padding: const EdgeInsets.only(top: 15, bottom: 40),
                      child: ElevatedButton.icon(
                        onPressed: _downloadSchedule,
                        icon: const Icon(Icons.download),
                        label: const Text("Download"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCell(String? title, String? venue, String? start, String? end) {
    return Container(
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.all(6),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const ui.Color.fromARGB(255, 241, 213, 246),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(venue ?? "", style: const TextStyle(fontSize: 9)),
          Text("${start ?? ""} - ${end ?? ""}", style: const TextStyle(fontSize: 7)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _organizerContent(), 
    );
  }
}