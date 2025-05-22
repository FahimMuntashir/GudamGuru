// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'header&nav.dart';
import 'database_helper.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
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

  TextStyle themedBoldTextStyle({
    required bool isDark,
    double fontSize = 16,
    FontWeight weight = FontWeight.bold,
  }) {
    return TextStyle(
      color: isDark ? Colors.white : deepIndigo,
      fontWeight: weight,
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    final bool isBangla = languageProvider.isBangla;

    return Scaffold(
      backgroundColor: isDark
          ? const Color.fromARGB(240, 0, 0, 0)
          : const Color.fromARGB(240, 255, 255, 255),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                  opacity: 0.1,
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 30),
              children: [
                buildHeader(context),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _noteController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: themedBoldTextStyle(isDark: isDark),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark ? darkShade1 : Colors.white,
                          hintText: isBangla
                              ? "একটি নোট লিখুন..."
                              : "Write a note...",
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white : deepIndigo,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark ? darkShade2 : deepIndigo,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark ? darkShade2 : deepIndigo,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? darkShade3
                                  : const Color.fromARGB(255, 13, 0, 255),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _addOrUpdateNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? darkShade1 : brightBlue,
                          side: BorderSide(
                            color: isDark ? darkShade3 : deepIndigo,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          editingIndex == null
                              ? (isBangla ? 'নোট যোগ করুন' : 'Add Note')
                              : (isBangla
                                  ? 'নোট হালনাগাদ করুন'
                                  : 'Update Note'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isDark
                              ? darkShade1.withOpacity(0.8)
                              : vibrantBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black45
                                  : Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: isDark ? darkShade3 : deepIndigo,
                            width: 2,
                          ),
                        ),
                        child: notes.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    isBangla
                                        ? 'এখনও কোনো নোট নেই।'
                                        : 'No notes yet.',
                                    style: themedBoldTextStyle(
                                      isDark: isDark,
                                      fontSize: 16,
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: notes.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  Map<String, dynamic> note = entry.value;
                                  bool isCompleted =
                                      note['completed'] == 'true';

                                  return Card(
                                    color: isDark
                                        ? darkShade2
                                        : Colors.grey.shade100,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color:
                                            isDark ? darkShade3 : vibrantBlue,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        note['text'],
                                        style: themedBoldTextStyle(
                                          isDark: isDark,
                                          weight: FontWeight.w500,
                                        ).copyWith(
                                          decoration: isCompleted
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                          color: isCompleted
                                              ? Colors.grey
                                              : (isDark
                                                  ? Colors.white
                                                  : Colors.black),
                                        ),
                                      ),
                                      subtitle: Text(
                                        DateFormat('MMM d, yyyy      h:mm a')
                                            .format(DateTime.parse(
                                                note['timestamp'])),
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value: isCompleted,
                                            onChanged: (_) =>
                                                _toggleCompleteNote(index),
                                            activeColor: isDark
                                                ? Colors.white
                                                : deepIndigo,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            color: isDark
                                                ? Colors.white
                                                : deepIndigo,
                                            onPressed: () => _editNote(index),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            color: isDark
                                                ? Colors.white
                                                : Colors.red,
                                            onPressed: () => _deleteNote(index),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottomNav(context, null),
    );
  }
}
