import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'models.dart';

Future<String> getDirectoryPath() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<void> saveList(ToDoList toDoList) async {
  final directoryPath = await getDirectoryPath();
  final filePath = '$directoryPath/${toDoList.id}.json';
  final file = File(filePath);
  await file.writeAsString(json.encode(toDoList.toJson()), flush: true);
}

Future<ToDoList> loadList(String listId) async {
  final directoryPath = await getDirectoryPath();
  final filePath = '$directoryPath/$listId.json';
  final file = File(filePath);

  if (await file.exists()) {
    final contents = await file.readAsString();
    final data = json.decode(contents);
    return ToDoList.fromJson(data);
  } else {
    throw Exception('List file not found');
  }
}

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

          // Skip empty lists
          if (toDoList.name.isEmpty && toDoList.tasks.isEmpty) {
            continue;
          }

          lists.add(toDoList);
        } catch (e) {
          print('Error reading file ${fileEntity.path}: $e');
          // Optionally, delete the corrupted file
          // await File(fileEntity.path).delete();
        }
      }
    }
  } catch (e) {
    print('Error loading lists: $e');
  }

  return lists;
}

Future<void> deleteListFile(String listId) async {
  final directoryPath = await getDirectoryPath();
  final filePath = '$directoryPath/$listId.json';
  final file = File(filePath);
  if (await file.exists()) {
    await file.delete();
  }
}
