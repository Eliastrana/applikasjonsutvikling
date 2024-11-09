import 'package:flutter/material.dart';
import 'list_screen.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart'; // Import intl package

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List App',
      theme: ThemeData(
        // Remove primarySwatch since we're specifying colors directly
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue, // Base swatch (can be any color)
        ).copyWith(
          primary: Colors.blue.shade100,   // Set your desired primary color
          secondary: Colors.blue.shade100, // Set your desired secondary color
          onPrimary: Colors.black,         // Text/icon color on primary color
          onSecondary: Colors.black,       // Text/icon color on secondary color
        ),
        // Update AppBarTheme to match your primary color
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade100,
          foregroundColor: Colors.black, // Text/icon color in AppBar
        ),
        // Update FloatingActionButtonTheme to match your secondary color
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue.shade100,
          foregroundColor: Colors.black, // Icon color in FAB
        ),
        // You can customize other theme properties as needed
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

}

class HomeScreen extends StatefulWidget {
  // The main screen displaying all lists
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> lists = [];
  late String directoryPath;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    final directory = await getApplicationDocumentsDirectory();
    directoryPath = directory.path;

    final dir = Directory(directoryPath);
    List<Map<String, dynamic>> tempLists = [];

    setState(() {
      lists.clear(); // Clear old lists
    });

    try {
      await for (var fileEntity in dir.list()) {
        if (fileEntity.path.endsWith('.json')) {
          try {
            final file = File(fileEntity.path);
            final contents = await file.readAsString();
            final data = json.decode(contents);

            String listName = data['listName'] ?? '';

            // Skip empty lists
            if (listName.isEmpty && (data['tasks']?.isEmpty ?? true)) {
              continue;
            }

            // Get the createdDate from data or use file's modified time
            DateTime createdDate;
            if (data['createdDate'] != null) {
              createdDate = DateTime.parse(data['createdDate']);
            } else {
              // Get the file's modified time as a fallback
              FileStat fstat = await file.stat();
              createdDate = fstat.modified;
            }

            tempLists.add({
              'id': file.path
                  .split(Platform.pathSeparator)
                  .last
                  .replaceAll('.json', ''),
              'name': listName,
              'createdDate': createdDate, // Add createdDate to the list
            });
          } catch (e) {
            // Handle exceptions for individual files
            print('Error reading file ${fileEntity.path}: $e');
            // Optionally, delete the corrupted file
            // await File(fileEntity.path).delete();
          }
        }
      }
    } catch (e) {
      print('Error loading lists: $e');
    }

    setState(() {
      // Sort the lists by createdDate, newest first
      tempLists.sort((a, b) => b['createdDate'].compareTo(a['createdDate']));
      lists = tempLists;
    });
  }


  void _createNewList() {
    String newListId = Uuid().v4();
    // Create a temporary list including the new list
    List<Map<String, dynamic>> tempAvailableLists = [
      ...lists,
      {'id': newListId, 'name': '', 'createdDate': DateTime.now()},
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListScreen(
          listId: newListId,
          listName: '',
          isNewList: true,
          availableLists: tempAvailableLists, // Pass the list of all available lists
        ),
      ),
    ).then((value) {
      if (value == 'reload') {
        _loadLists();
      }
    });
  }

  void _deleteList(String listId) async {
    final file = File('$directoryPath${Platform.pathSeparator}$listId.json');
    if (await file.exists()) {
      await file.delete();
      print('File deleted: ${file.path}');
    } else {
      print('File not found: ${file.path}');
    }

    await _loadLists();
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

  Widget _buildListTile(Map<String, dynamic> list) {
    // Format the creation date
    String formattedDate =
    DateFormat('dd.MM.yyyy').format(list['createdDate']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListScreen(
              listId: list['id'],
              listName: list['name'],
              isNewList: false,
              availableLists: lists, // Pass the actual lists here
            ),
          ),
        ).then((value) {
          if (value == 'reload') {
            _loadLists();
          }
        });
      },
      onLongPress: () {
        _showDeleteConfirmation(list['id'], list['name']);
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
              list['name'],
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
