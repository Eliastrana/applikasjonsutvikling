import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'models.dart';

/// Retrieves the path to the application's documents directory where to-do lists are stored.
///
/// Returns the directory path as a [String].
Future<String> getDirectoryPath() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

/// Saves a [ToDoList] object to a JSON file in the local storage.
///
/// [toDoList] The to-do list to save.
///
/// Throws an exception if an error occurs during the save process.
Future<void> saveList(ToDoList toDoList) async {
  final directoryPath = await getDirectoryPath();
  final filePath = '$directoryPath/${toDoList.id}.json';
  final file = File(filePath);

  try {
    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    await file.writeAsString(json.encode(toDoList.toJson()), flush: true);
  } catch (e) {
    print('Error saving list: $e');
    rethrow;
  }
}

/// Loads a [ToDoList] from a JSON file based on the provided list ID.
///
/// If the file does not exist, it creates a placeholder list.
///
/// [listId] The unique identifier of the to-do list.
///
/// Returns the loaded [ToDoList].
///
/// Throws an exception if an error occurs during the load process.
Future<ToDoList> loadList(String listId) async {
  final directoryPath = await getDirectoryPath();
  final filePath = '$directoryPath/$listId.json';
  final file = File(filePath);

  try {
    if (await file.exists()) {
      final contents = await file.readAsString();
      final data = json.decode(contents);
      return ToDoList.fromJson(data);
    } else {
      print('List file not found, creating placeholder for ID: $listId');
      final placeholderList = ToDoList(
        id: listId,
        name: '',
        createdDate: DateTime.now(),
        tasks: [],
      );
      await saveList(placeholderList);
      return placeholderList;
    }
  } catch (e) {
    print('Error loading list: $e');
    throw Exception('Failed to load list');
  }
}

/// Loads all to-do lists from the local storage by reading all JSON files in the documents directory.
///
/// Returns a list of [ToDoList] objects.
Future<List<ToDoList>> loadAllLists() async {
  final directoryPath = await getDirectoryPath();
  final dir = Directory(directoryPath);
  List<ToDoList> lists = [];

  try {
    await for (var fileEntity in dir.list()) {
      if (fileEntity.path.endsWith('.json')) {
        try {
          final file = File(fileEntity.path);
          final contents = await file.readAsString();
          final data = json.decode(contents);
          ToDoList toDoList = ToDoList.fromJson(data);

          if (toDoList.name.isEmpty && toDoList.tasks.isEmpty) {
            continue;
          }

          lists.add(toDoList);
        } catch (e) {
          print('Error reading file ${fileEntity.path}: $e');
        }
      }
    }
  } catch (e) {
    print('Error loading lists: $e');
  }
  return lists;
}

/// Deletes the JSON file corresponding to the specified to-do list ID from the local storage.
///
/// [listId] The unique identifier of the to-do list to delete.
Future<void> deleteListFile(String listId) async {
  final directoryPath = await getDirectoryPath();
  final filePath = '$directoryPath/$listId.json';
  final file = File(filePath);
  if (await file.exists()) {
    await file.delete();
  }
}
