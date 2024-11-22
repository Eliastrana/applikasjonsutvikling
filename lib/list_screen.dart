import 'package:flutter/material.dart';
import 'models.dart';
import 'task_widget.dart';
import 'file_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

/// The ListScreen widget allows users to view and manage tasks within a specific to-do list.
///
/// Users can add, delete, and reorder tasks, as well as delete the entire list.
class ListScreen extends StatefulWidget {
  /// The current to-do list being managed.
  final ToDoList toDoList;

  /// Indicates whether the to-do list is newly created.
  final bool isNewList;

  /// A list of all available to-do lists for navigation.
  final List<ToDoList> availableLists;

  /// Creates a [ListScreen].
  ///
  /// [toDoList] The to-do list to manage.
  /// [isNewList] Whether the to-do list is new.
  /// [availableLists] The list of available to-do lists.
  ListScreen({
    Key? key,
    required this.toDoList,
    required this.isNewList,
    required this.availableLists,
  }) : super(key: key);

  @override
  _ListScreenState createState() => _ListScreenState();
}

/// The state for [ListScreen].
///
/// Manages loading tasks, adding new tasks, deleting tasks, and handling list deletions.
class _ListScreenState extends State<ListScreen> {
  /// The current to-do list being managed.
  late ToDoList toDoList;

  /// Controller for the task input field.
  late TextEditingController _taskController;

  /// Focus node for the task input field.
  final FocusNode _taskFocusNode = FocusNode();

  /// Indicates whether the current list has been deleted.
  bool _isDeleted = false;

  @override
  void initState() {
    super.initState();
    toDoList = widget.toDoList;
    _taskController = TextEditingController();
    _loadTasks();

    if (widget.isNewList) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _promptForListTitle();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_taskFocusNode);
    });
  }

  /// Loads tasks from local storage for the current to-do list.
  Future<void> _loadTasks() async {
    try {
      ToDoList loadedList = await loadList(toDoList.id);
      setState(() {
        toDoList = loadedList;
      });
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }

  /// Saves the current state of the to-do list to local storage.
  Future<void> _saveTasks() async {
    if (_isDeleted) return;
    await saveList(toDoList);
  }

  /// Adds a new task to the to-do list.
  ///
  /// [title] The title of the new task.
  void _addTask(String title) {
    if (title.trim().isEmpty) return;

    setState(() {
      Task newTask = Task(
        id: Uuid().v4(),
        title: title.trim(),
        completed: false,
      );
      toDoList.tasks.add(newTask);
      _sortTasks();
    });

    _saveTasks();

    _taskController.clear();
    FocusScope.of(context).requestFocus(_taskFocusNode);
  }

  /// Deletes a task at the specified index from the to-do list.
  ///
  /// [index] The index of the task to delete.
  void _deleteTask(int index) async {
    if (index < 0 || index >= toDoList.tasks.length) return;
    setState(() {
      toDoList.tasks.removeAt(index);
    });
    await _saveTasks();
  }

  /// Displays a confirmation dialog before deleting a task.
  ///
  /// [index] The index of the task to delete.
  void _showDeleteConfirmation(int index) {
    if (index < 0 || index >= toDoList.tasks.length) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Slett oppgave',
            style: TextStyle(color: Colors.black),
          ),
          content: Text(
            'Er du sikker på at du vil slette oppgaven "${toDoList.tasks[index].title}"?',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTask(index);
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

  /// Displays a confirmation dialog before deleting the entire to-do list.
  void _showDeleteListConfirmation() {
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
              child: Text('Slett',
                  style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Avbryt',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Deletes the current to-do list and navigates back to the home screen.
  void _deleteCurrentList() async {
    await deleteListFile(toDoList.id);
    setState(() {
      _isDeleted = true;
    });
    Navigator.of(context).pop('reload');
  }

  /// Prompts the user to enter a title for a new to-do list.
  void _promptForListTitle() {
    TextEditingController _titleController =
    TextEditingController(text: toDoList.name);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Gi listen et navn'),
          content: TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Tittel',

            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (value) {
              _updateListTitle(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                String title = _titleController.text.trim();
                _updateListTitle(title);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Updates the title of the current to-do list.
  ///
  /// [title] The new title for the to-do list.
  void _updateListTitle(String title) {
    if (title.isNotEmpty) {
      setState(() {
        toDoList.name = title;

        final listIndex = widget.availableLists.indexWhere(
              (list) => list.id == toDoList.id,
        );
        if (listIndex != -1) {
          widget.availableLists[listIndex].name = title;
        }
      });
      _saveTasks();
      Navigator.of(context).pop('reload');
    }
  }

  /// Sorts tasks based on their completion status.
  ///
  /// Incomplete tasks appear before completed tasks.
  void _sortTasks() {
    toDoList.tasks.sort((a, b) {
      if (a.completed == b.completed) {
        return 0;
      } else if (a.completed) {
        return 1;
      } else {
        return -1;
      }
    });
  }

  @override
  void dispose() {
    _saveTasks();
    _taskController.dispose();
    _taskFocusNode.dispose();
    super.dispose();
  }

  /// Builds UI elements for navigating between available to-do lists.
  ///
  /// Returns a [Widget] containing pills for each available list.
  Widget _buildAvailableListsPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.availableLists.map((list) {
          bool isCurrent = list.id == toDoList.id;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () {
                if (!isCurrent) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListScreen(
                        toDoList: list,
                        isNewList: false,
                        availableLists: widget.availableLists,
                      ),
                    ),
                  ).then((_) => _loadTasks());
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrent ? Colors.blue.shade100 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  list.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
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
    // Ensure tasks are sorted whenever the widget rebuilds
    _sortTasks();

    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _showDeleteListConfirmation,
            tooltip: 'Delete List',
          ),
        ],
      ),
      body: Column(
        children: [
          // Available Lists Pills
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildAvailableListsPills(),
          ),
          // List name and date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft, // Ensure left alignment
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Ensure left alignment
                children: [
                  GestureDetector(
                    onTap: () {
                      _promptForListTitle(); // Open the title editing dialog
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            toDoList.name.isEmpty
                                ? ' '
                                : toDoList.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.grey,
                        ), // Add an edit icon
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat('dd.MM.yyyy').format(toDoList.createdDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          // Fixed Input field for adding tasks
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    focusNode: _taskFocusNode,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Legg til nytt punkt',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (value) {
                      _addTask(value);
                    },
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    _addTask(_taskController.text);
                  },
                  tooltip: 'Add Task',
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Task list
          Expanded(
            child: toDoList.tasks.isEmpty
                ? Center(
              child: Text(
                'Ingen oppgaver ennå.\nLegg til en oppgave over.',
                textAlign: TextAlign.center,
                style:
                TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            )
                : ReorderableListView(
              padding: EdgeInsets.only(bottom: 16),
              children: [
                for (int index = 0; index < toDoList.tasks.length; index++)
                  TaskWidget(
                    key: ValueKey(toDoList.tasks[index].id),
                    task: toDoList.tasks[index],
                    onCheckboxChanged: (bool? value) {
                      setState(() {
                        toDoList.tasks[index].completed =
                            value ?? false;
                        _sortTasks();
                      });
                      _saveTasks();
                    },
                    onDelete: () {
                      _showDeleteConfirmation(index);
                    },
                  ),
              ],
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final task = toDoList.tasks.removeAt(oldIndex);
                  toDoList.tasks.insert(newIndex, task);
                  _sortTasks();
                });
                _saveTasks();
              },
            ),
          ),
        ],
      ),
    );
  }
}
