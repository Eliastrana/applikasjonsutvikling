import 'package:flutter/material.dart';
import 'list_screen.dart';
import 'models.dart';
import 'file_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

/// The HomeScreen widget displays all available to-do lists and provides
/// functionality to create new lists or delete existing ones.
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

/// The state for [HomeScreen].
///
/// Manages loading, creating, and deleting to-do lists.
class _HomeScreenState extends State<HomeScreen> {
  /// The list of all available to-do lists.
  List<ToDoList> lists = [];

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  /// Loads all existing to-do lists from local storage and updates the state.
  Future<void> _loadLists() async {
    List<ToDoList> loadedLists = await loadAllLists();
    setState(() {
      loadedLists.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      lists = loadedLists;
    });
  }

  /// Creates a new to-do list with a unique ID and navigates to the [ListScreen] for editing.
  void _createNewList() {
    String newListId = Uuid().v4();
    ToDoList newList = ToDoList(
      id: newListId,
      name: '',
      createdDate: DateTime.now(),
      tasks: [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListScreen(
          toDoList: newList,
          isNewList: true,
          availableLists: [...lists, newList],
        ),
      ),
    ).then((_) {
      _loadLists();
    });
  }

  /// Deletes a specified to-do list by its ID and refreshes the list of available lists.
  ///
  /// [listId] The unique identifier of the to-do list to delete.
  void _deleteList(String listId) async {
    await deleteListFile(listId);
    _loadLists();
  }

  /// Displays a confirmation dialog before deleting a to-do list.
  ///
  /// [listId] The unique identifier of the to-do list.
  /// [listName] The name of the to-do list.
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
              child: Text(
                'Slett',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Avbryt',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds the UI element for adding a new to-do list.
  ///
  /// Returns a [Widget] representing the add new list tile.
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
          semanticLabel: 'Add New List',
        ),
      ),
    );
  }

  /// Builds the UI element for an individual to-do list.
  ///
  /// [list] The [ToDoList] to display.
  ///
  /// Returns a [Widget] representing the list tile.
  Widget _buildListTile(ToDoList list) {
    String formattedDate = DateFormat('dd.MM.yyyy').format(list.createdDate);

    String displayTitle = list.name.length > 20
        ? '${list.name.substring(0, 20)}...'
        : list.name;

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
        ).then((_) {
          _loadLists();
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
              displayTitle.isEmpty ? 'Uten tittel' : displayTitle,
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
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: lists.isEmpty
            ? Center(child: _buildAddNewListTile())
            : GridView.count(
          crossAxisCount:
          MediaQuery.of(context).orientation == Orientation.portrait
              ? 2
              : 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: tiles,
        ),
      ),
    );
  }
}
