import 'package:flutter/material.dart';
import 'models.dart'; // Import models
import 'task_widget.dart'; // Import TaskWidget
import 'file_utils.dart'; // Import file utilities
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class ListScreen extends StatefulWidget {
  final ToDoList toDoList;
  final bool isNewList;
  final List<ToDoList> availableLists;

  ListScreen({
    required this.toDoList,
    required this.isNewList,
    required this.availableLists,
  });

  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late ToDoList toDoList;
  late TextEditingController _listNameController;
  bool _isDeleted = false;
  String? _focusedTaskId;

  @override
  void initState() {
    super.initState();
    toDoList = widget.toDoList;
    _listNameController = TextEditingController(text: toDoList.name);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    ToDoList loadedList = await loadList(toDoList.id);
    setState(() {
      toDoList = loadedList;
      _listNameController.text = toDoList.name;
    });
  }

  Future<void> _saveTasks() async {
    if (_isDeleted) return; // Do not save if the list has been deleted
    toDoList.name = _listNameController.text;
    await saveList(toDoList);
  }

  void _addTaskAtIndex(int index) {
    // Generate a unique id for the new task
    final newId = Uuid().v4();

    setState(() {
      toDoList.tasks.insert(index + 1, Task(id: newId, title: '', completed: false));
      _focusedTaskId = newId; // Set the focused task ID
    });

    // Clear the focused task ID after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _focusedTaskId = null;
      });
    });
  }

  void _deleteTaskAndFocusPrevious(int index) {
    setState(() {
      toDoList.tasks.removeAt(index);
    });

    int previousIndex = index - 1;
    if (previousIndex >= 0 && previousIndex < toDoList.tasks.length) {
      setState(() {
        _focusedTaskId = toDoList.tasks[previousIndex].id;
      });
    } else if (toDoList.tasks.isNotEmpty) {
      setState(() {
        _focusedTaskId = toDoList.tasks[0].id;
      });
    }

    // Clear the focused task ID after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _focusedTaskId = null;
      });
    });

    _saveTasks();
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Slett liste'),
          content: Text('Er du sikker på at du vil slette denne listen?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCurrentList();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              child: Text('Slett'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              child: Text('Avbryt'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCurrentList() async {
    // Delete the list file
    await deleteListFile(toDoList.id);
    setState(() {
      _isDeleted = true; // Mark the list as deleted
    });
    Navigator.of(context).pop('reload'); // Pass 'reload' back to HomeScreen
  }

  @override
  void dispose() {
    _saveTasks(); // Save the list when the screen is disposed
    _listNameController.dispose();
    super.dispose();
  }

  Widget _buildAvailableListsPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // Left-align the pills
        children: widget.availableLists
            .where((list) => list.name.isNotEmpty) // Filter lists with a name
            .map((list) {
          // Determine if this list is the current list
          bool isCurrentList = list.id == toDoList.id;

          return GestureDetector(
            onTap: () {
              if (!isCurrentList) {
                // Navigate to the selected list
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListScreen(
                      toDoList: list,
                      isNewList: false,
                      availableLists: widget.availableLists,
                    ),
                  ),
                );
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isCurrentList ? Colors.blue.shade100 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                list.name,
                style: TextStyle(
                  color: isCurrentList ? Colors.black : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format the creation date
    String formattedDate = DateFormat('dd.MM.yyyy').format(toDoList.createdDate);

    return WillPopScope(
      onWillPop: () async {
        // Return 'reload' when navigating back
        Navigator.of(context).pop('reload');
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        // Allow the Scaffold to adjust when the keyboard appears
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(''),
          actions: [
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _showDeleteConfirmation();
              },
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Horizontal list of available lists
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildAvailableListsPills(),
            ),
            // List name TextField and creation date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _listNameController,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Skriv inn navn på listen',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {
                        toDoList.name = value;
                      });
                      // Save the name change
                      _saveTasks();
                    },
                    onSubmitted: (value) {
                      // Automatically start a new task when Enter is pressed
                      if (toDoList.tasks.isEmpty) {
                        _addTaskAtIndex(-1); // Add at the beginning
                      }
                    },
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$formattedDate',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            // Expanded widget to fill the remaining space
            Expanded(
              child: toDoList.tasks.isEmpty
                  ? Center(
                child: Text(
                  'Ingen oppgaver ennå.\nTrykk på "+" for å legge til en.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              )
                  : ReorderableListView.builder(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final task = toDoList.tasks.removeAt(oldIndex);
                    toDoList.tasks.insert(newIndex, task);
                  });
                  _saveTasks();
                },
                itemCount: toDoList.tasks.length,
                itemBuilder: (context, index) {
                  Task task = toDoList.tasks[index];

                  return TaskWidget(
                    key: ValueKey(task.id),
                    index: index, // Pass the index
                    task: task,
                    shouldFocus: task.id == _focusedTaskId,
                    onUpdate: (updatedTask) {
                      setState(() {
                        bool previousCompletedStatus = toDoList.tasks[index].completed;
                        toDoList.tasks[index] = updatedTask;
                        if (updatedTask.completed != previousCompletedStatus) {
                          // Remove the task from its current position
                          final task = toDoList.tasks.removeAt(index);
                          if (updatedTask.completed) {
                            // Move the task to the bottom
                            toDoList.tasks.add(task);
                          } else {
                            // Move the task to the top
                            toDoList.tasks.insert(0, task);
                          }
                        }
                      });
                      _saveTasks();
                    },
                    onDelete: () {
                      _deleteTaskAndFocusPrevious(index);
                    },
                    onAddTask: () {
                      _addTaskAtIndex(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _addTaskAtIndex(toDoList.tasks.length - 1);
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
