import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class ListScreen extends StatefulWidget {
  final String listId;
  String listName;
  final bool isNewList;
  final List<Map<String, dynamic>> availableLists;

  ListScreen({
    required this.listId,
    required this.listName,
    required this.isNewList,
    required this.availableLists,
  });

  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<Map<String, dynamic>> tasks = [];
  late String filePath;
  late TextEditingController _listNameController;
  bool _isDeleted = false;
  DateTime createdDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _listNameController = TextEditingController(text: widget.listName);
    _initializeFilePathAndLoadTasks();
  }

  // Helper method to initialize filePath and load tasks
  void _initializeFilePathAndLoadTasks() async {
    await _initializeFilePath();

    // Ensure the directory exists
    final dir = Directory(filePath).parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    await _loadTasks();
  }

  Future<void> _initializeFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    filePath = '${directory.path}/${widget.listId}.json';
  }

  Future<void> _loadTasks() async {
    final file = File(filePath);

    if (await file.exists()) {
      try {
        final contents = await file.readAsString();
        final data = json.decode(contents);

        // Get the createdDate from data or use file's modified time
        DateTime tempCreatedDate;
        if (data['createdDate'] != null) {
          tempCreatedDate = DateTime.parse(data['createdDate']);
        } else {
          // Get the file's modified time as a fallback
          FileStat fstat = await file.stat();
          tempCreatedDate = fstat.modified;
        }

        setState(() {
          widget.listName = data['listName'] ?? widget.listName;
          _listNameController.text = widget.listName;
          tasks = List<Map<String, dynamic>>.from(data['tasks'] ?? []);
          createdDate = tempCreatedDate; // Set the createdDate

          // Initialize TextEditingController, FocusNode, and assign unique id for each task
          for (var task in tasks) {
            task['controller'] = TextEditingController(text: task['title']);
            task['focusNode'] = FocusNode();
            task['editing'] = false;

            // Assign a unique id if not present
            if (!task.containsKey('id')) {
              task['id'] = DateTime.now().millisecondsSinceEpoch.toString() +
                  (tasks.indexOf(task)).toString();
            }
          }
        });
      } catch (e) {
        print('Error loading tasks from $filePath: $e');
        setState(() {
          tasks = [];
          createdDate = DateTime.now();
        });
      }
    } else {
      setState(() {
        tasks = [];
        createdDate = DateTime.now();
      });
    }
  }

  Future<void> _saveTasks() async {
    if (_isDeleted) return; // Do not save if the list has been deleted

    // Ensure filePath is initialized
    if (filePath.isEmpty) {
      await _initializeFilePath();
    }

    // Ensure the directory exists
    final fileDir = File(filePath).parent;
    if (!await fileDir.exists()) {
      await fileDir.create(recursive: true);
    }

    List<Map<String, dynamic>> tasksToSave = tasks.map((task) {
      return {
        'id': task['id'],
        'title': task['title'],
        'completed': task['completed'],
      };
    }).toList();

    final data = {
      'listName': widget.listName,
      'tasks': tasksToSave,
      'createdDate': createdDate.toIso8601String(),
    };

    final file = File(filePath);
    await file.writeAsString(json.encode(data), flush: true);
  }

  // Save only the task's text without adding a new task
  void _saveTask(int index) {
    final controller = tasks[index]['controller'] as TextEditingController;
    String text = controller.text.trim();

    setState(() {
      tasks[index]['title'] = text;
      tasks[index]['editing'] = false;
    });

    _saveTasks();
  }

  // Save the task's text and add a new task if the current task is not empty
  void _onSubmitted(int index) {
    final controller = tasks[index]['controller'] as TextEditingController;
    String text = controller.text.trim();

    setState(() {
      tasks[index]['title'] = text;
      tasks[index]['editing'] = false;
    });

    if (text.isNotEmpty) {
      // Add a new task immediately after the current one
      _addTaskAtIndex(index);
    } else {
      // If the task is empty, focus should stay on the current task
      FocusScope.of(context).requestFocus(tasks[index]['focusNode'] as FocusNode);
    }

    _saveTasks();
  }


  void _updateTask(int index, bool? value) {
    setState(() {
      tasks[index]['completed'] = value ?? false;

      if (tasks[index]['completed']) {
        // Move the completed task to the bottom
        final task = tasks.removeAt(index);
        tasks.add(task);
      }
    });
    _saveTasks();
  }

  void _addTaskAtIndex(int index) {
    final newController = TextEditingController();
    final newFocusNode = FocusNode();

    // Generate a unique id for the new task
    final newId = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      tasks.insert(index + 1, {
        'id': newId,
        'title': '',
        'completed': false,
        'editing': true,
        'controller': newController,
        'focusNode': newFocusNode,
      });
    });

    // Delay focus request to allow the widget tree to rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(newFocusNode);
      // Scroll to the new task to ensure it's visible
      _scrollToTask(index + 1);
    });
  }

  void _scrollToTask(int index) {
    // Use Scrollable.ensureVisible for precise scrolling
    Future.delayed(Duration(milliseconds: 300), () {
      Scrollable.ensureVisible(
        context,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onTaskTap(int index) {
    setState(() {
      tasks[index]['editing'] = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      tasks[index]['focusNode'].requestFocus();
    });
  }

  void _deleteTaskAndFocusPrevious(int index) {
    // Dispose the controller and focusNode of the task being deleted
    tasks[index]['controller'].dispose();
    tasks[index]['focusNode'].dispose();

    setState(() {
      tasks.removeAt(index);
    });

    if (index > 0) {
      setState(() {
        tasks[index - 1]['editing'] = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tasks[index - 1]['focusNode'].requestFocus();
        tasks[index - 1]['controller'].selection = TextSelection.fromPosition(
            TextPosition(offset: tasks[index - 1]['controller'].text.length));
      });
    } else if (tasks.isNotEmpty) {
      setState(() {
        tasks[0]['editing'] = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tasks[0]['focusNode'].requestFocus();
        tasks[0]['controller'].selection = TextSelection.fromPosition(
            TextPosition(offset: tasks[0]['controller'].text.length));
      });
    }

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
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
    setState(() {
      _isDeleted = true; // Mark the list as deleted
    });
    Navigator.of(context).pop('reload'); // Pass 'reload' back to HomeScreen
  }

  @override
  void dispose() {
    _saveTasks(); // Save the list when the screen is disposed
    // Dispose all TextEditingControllers and FocusNodes
    for (var task in tasks) {
      (task['controller'] as TextEditingController).dispose();
      (task['focusNode'] as FocusNode).dispose();
    }
    _listNameController.dispose();
    super.dispose();
  }

  Widget _buildAvailableListsPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // Left-align the pills
        children: widget.availableLists
            .where((list) => list['name'] != null && list['name'].isNotEmpty) // Filter lists with a name
            .map((list) {
          // Determine if this list is the current list
          bool isCurrentList = list['id'] == widget.listId;

          return GestureDetector(
            onTap: () {
              if (!isCurrentList) {
                // Navigate to the selected list
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListScreen(
                      listId: list['id'],
                      listName: list['name'],
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
                color: isCurrentList
                    ? Colors.blue.shade100
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                list['name'],
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
    String formattedDate = DateFormat('dd.MM.yyyy').format(createdDate);

    return WillPopScope(
      onWillPop: () async {
        // Return 'reload' when navigating back
        Navigator.of(context).pop('reload');
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        resizeToAvoidBottomInset:
        true, // Ensure the Scaffold adjusts when the keyboard appears
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
          children: [
            // Horizontal list of available lists
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildAvailableListsPills(), // Horizontal list of pills
            ),
            // List name TextField and creation date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _listNameController,
                    style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Skriv inn navn på listen',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {
                        widget.listName = value;
                      });
                      // Save the name change
                      _saveTasks();
                    },
                    onSubmitted: (value) {
                      // Automatically start a new task when Enter is pressed
                      if (tasks.isEmpty) {
                        _addTaskAtIndex(-1); // Add at the beginning
                      } else {
                        // Focus on the last task if it exists
                        _onTaskTap(tasks.length - 1);
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
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                child: Text(
                  'Ingen oppgaver ennå.\nTrykk på "+" for å legge til en.',
                  textAlign: TextAlign.center,
                  style:
                  TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              )
                  : ReorderableListView.builder(
                itemCount: tasks.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = tasks.removeAt(oldIndex);
                    tasks.insert(newIndex, item);
                  });
                  _saveTasks();
                },
                proxyDecorator:
                    (Widget child, int index, Animation<double> animation) {
                  return Material(
                    elevation: 6.0,
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  return ListTile(
                    key: ValueKey(tasks[index]['id']),
                    trailing: Icon(Icons.drag_handle),
                    leading: Checkbox(
                      value: tasks[index]['completed'],
                      onChanged: (bool? value) {
                        _updateTask(index, value);
                      },
                    ),
                    title: tasks[index]['editing']
                        ? TextField(
                      controller: tasks[index]['controller'] as TextEditingController,
                      focusNode: tasks[index]['focusNode'] as FocusNode,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _onSubmitted(index),
                      onChanged: (text) {
                        if (text.isEmpty) {
                          _deleteTaskAndFocusPrevious(index);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Skriv inn...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        fontSize: 18, // Consistent font size
                      ),
                    )
                        : GestureDetector(
                      onTap: () {
                        _onTaskTap(index);
                      },
                      child: Text(
                        tasks[index]['title'],
                        style: TextStyle(
                          decoration: tasks[index]['completed']
                              ? TextDecoration.lineThrough
                              : null,
                          fontSize: 18, // Consistent font size
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _addTaskAtIndex(tasks.length - 1);
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
