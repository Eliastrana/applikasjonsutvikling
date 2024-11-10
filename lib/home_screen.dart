import 'package:flutter/material.dart';
import 'list_screen.dart'; // Import ListScreen
import 'models.dart'; // Import models
import 'file_utils.dart'; // Import file utilities
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  // The main screen displaying all lists
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ToDoList> lists = [];

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    List<ToDoList> loadedLists = await loadAllLists();
    setState(() {
      // Sort the lists by createdDate, newest first
      loadedLists.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      lists = loadedLists;
    });
  }

  void _createNewList() {
    String newListId = Uuid().v4();
    ToDoList newList = ToDoList(
      id: newListId,
      name: '',
      createdDate: DateTime.now(),
      tasks: [],
    );

    List<ToDoList> tempAvailableLists = [...lists, newList];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListScreen(
          toDoList: newList,
          isNewList: true,
          availableLists: tempAvailableLists,
        ),
      ),
    ).then((value) {
      if (value == 'reload') {
        _loadLists();
      }
    });
  }

  void _deleteList(String listId) async {
    await deleteListFile(listId);
    _loadLists();
  }

  void _showDeleteConfirmation(String listId, String listName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Slett liste'),
          content: Text('Er du sikker på at du vil slette "$listName"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteList(listId);
              },
              child: Text('Slett'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Avbryt'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddNewListTile() {
    return GestureDetector(
      onTap: _createNewList,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade100),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.add,
          size: 50,
          color: Colors.blue.shade100,
        ),
      ),
    );
  }

  Widget _buildListTile(ToDoList list) {
    // Format the creation date
    String formattedDate = DateFormat('dd.MM.yyyy').format(list.createdDate);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListScreen(
              toDoList: list,
              isNewList: false,
              availableLists: lists,
            ),
          ),
        ).then((value) {
          if (value == 'reload') {
            _loadLists();
          }
        });
      },
      onLongPress: () {
        _showDeleteConfirmation(list.id, list.name);
      },
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              list.name,
              style: TextStyle(
                fontSize: 20,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _buildAddNewListTile(),
      ...lists.map((list) => _buildListTile(list)).toList(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Lister'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: lists.isEmpty
            ? Center(child: _buildAddNewListTile())
            : GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: tiles,
        ),
      ),
    );
  }
}
