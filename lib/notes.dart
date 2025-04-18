import 'package:flutter/material.dart';

import 'UserSession.dart';
import 'database_helper.dart';
import 'homepage.dart';
import 'inventory.dart';
import 'profile.dart';
import 'reportanalytics.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, dynamic>> notes = [];
  final TextEditingController _noteController = TextEditingController();
  int? editingIndex;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      List<Map<String, dynamic>> loadedNotes = await _dbHelper.getAllNotes();
      print('Loaded notes: ${loadedNotes.length}'); // Debug log
      setState(() {
        notes = loadedNotes.map((note) {
          return {
            'id': note['id'],
            'text': note['text'],
            'timestamp': note['timestamp'],
            'completed': note['completed'] == 1 ? 'true' : 'false'
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading notes: $e'); // Debug log
    }
  }

  Future<void> _addOrUpdateNote() async {
    if (_noteController.text.isNotEmpty) {
      try {
        if (editingIndex == null) {
          print('Adding new note: ${_noteController.text}'); // Debug log
          await _dbHelper
              .insertNote({'text': _noteController.text, 'completed': 'false'});
        } else {
          print('Updating note at index $editingIndex'); // Debug log
          await _dbHelper.updateNote(notes[editingIndex!]['id'], {
            'text': _noteController.text,
            'timestamp': DateTime.now().toIso8601String()
          });
          editingIndex = null;
        }
        _noteController.clear();
        await _loadNotes();
      } catch (e) {
        print('Error adding/updating note: $e'); // Debug log
      }
    }
  }

  Future<void> _toggleCompleteNote(int index) async {
    await _dbHelper.updateNote(notes[index]['id'],
        {'completed': notes[index]['completed'] == 'true' ? 'false' : 'true'});
    _loadNotes();
  }

  void _editNote(int index) {
    setState(() {
      _noteController.text = notes[index]['text'];
      editingIndex = index;
    });
  }

  Future<void> _deleteNote(int index) async {
    await _dbHelper.deleteNote(notes[index]['id']);
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(5),
                            bottomRight: Radius.circular(5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset('assets/images/logo.png', width: 150),
                            Text(
                              (UserSession().companyName!),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            TextField(
                              controller: _noteController,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              decoration: InputDecoration(
                                hintText: 'Write a note...',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _addOrUpdateNote,
                              child: Text(editingIndex == null
                                  ? 'Add Note'
                                  : 'Update Note'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: notes.asMap().entries.map((entry) {
                              int index = entry.key;
                              Map<String, dynamic> note = entry.value;
                              bool isCompleted = note['completed'] == 'true';
                              return Card(
                                child: ListTile(
                                  title: Text(
                                    note['text'],
                                    style: TextStyle(
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: isCompleted
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                  subtitle: Text(note['timestamp']),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: isCompleted,
                                        onChanged: (_) =>
                                            _toggleCompleteNote(index),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () => _editNote(index),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _deleteNote(index),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
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

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xff000000),
        unselectedItemColor: Colors.black,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const InventoryPage()),
            );
          }
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const ReportAnalyticsPage()),
            );
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory), label: 'Inventory'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Report & Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
