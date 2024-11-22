import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';


/// A widget that represents a single task item with a checkbox, title, and delete option.
///
/// Includes functionality for marking tasks as completed and deleting tasks.
class TaskWidget extends StatelessWidget {
  /// The task data to be displayed.
  final Task task;
  /// Callback invoked when the task's completion status changes.
  final ValueChanged<bool?> onCheckboxChanged;
  /// Callback invoked when the task is to be deleted.
  final VoidCallback onDelete;

  /// Creates a [TaskWidget].
  ///
  /// [task] The task to display.
  /// [onCheckboxChanged] Callback for checkbox changes.
  /// [onDelete] Callback for delete action.
  TaskWidget({
    Key? key,
    required this.task,
    required this.onCheckboxChanged,
    required this.onDelete,
  }) : super(key: key);

  /// Handles changes to the task's checkbox, providing haptic feedback upon completion.
  ///
  /// [context] The build context.
  /// [value] The new value of the checkbox.
  void _handleCheckboxChanged(BuildContext context, bool? value) {
    if (value == true) {
      HapticFeedback.lightImpact();
    }
    onCheckboxChanged(value);
  }

  /// Builds the widget.
  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey(task.id),
      leading: Checkbox(
        value: task.completed,
        onChanged: (value) => _handleCheckboxChanged(context, value),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          fontSize: 18,
          decoration:
          task.completed ? TextDecoration.lineThrough : TextDecoration.none,
          color: task.completed ? Colors.grey : Colors.black,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.drag_handle, color: Colors.grey),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.grey),
            onPressed: onDelete,
            tooltip: 'Delete Task',
          ),
        ],
      ),
    );
  }
}
