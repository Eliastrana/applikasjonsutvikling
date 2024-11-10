import 'package:flutter/material.dart';
import 'models.dart';
import 'package:flutter/services.dart';

class TaskWidget extends StatefulWidget {
  final int index;
  final Task task;
  final ValueChanged<Task> onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onAddTask;
  final bool shouldFocus;

  TaskWidget({
    Key? key,
    required this.index,
    required this.task,
    required this.onUpdate,
    required this.onDelete,
    required this.onAddTask,
    this.shouldFocus = false,
  }) : super(key: key);

  @override
  _TaskWidgetState createState() => _TaskWidgetState();
}

class _TaskWidgetState extends State<TaskWidget> with AutomaticKeepAliveClientMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _lastKeyWasBackspace = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.title);
    _focusNode = FocusNode();

    // Assign the onKey callback
    _focusNode.onKey = _handleKeyEvent;

    if (widget.shouldFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Check if the backspace key is pressed
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        // If the text is empty, delete the task
        if (_controller.text.isEmpty) {
          widget.onDelete();
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        // Handle the Enter key to add a new task
        String text = _controller.text.trim();
        if (text.isNotEmpty) {
          widget.onUpdate(
            widget.task.copyWith(title: text),
          );
          // Defer adding new task until after the frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onAddTask();
          });
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void didUpdateWidget(covariant TaskWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldFocus && !oldWidget.shouldFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _onChanged(String value) {
    // Update the task as the user types
    widget.onUpdate(
      widget.task.copyWith(title: value),
    );
  }

  void _onTap() {
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListTile(
      key: ValueKey(widget.task.id),
      leading: Checkbox(
        value: widget.task.completed,
        onChanged: (bool? value) {
          widget.onUpdate(
            widget.task.copyWith(completed: value ?? false),
          );
        },
      ),
      title: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: false,
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.text,
        maxLines: 1,
        decoration: InputDecoration(
          hintText: 'Skriv inn...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
        ),
        style: TextStyle(
          fontSize: 18,
          decoration: widget.task.completed ? TextDecoration.lineThrough : null,
        ),
        onChanged: _onChanged,
        onTap: _onTap,
        onSubmitted: (value) {
          String text = _controller.text.trim();
          if (text.isNotEmpty) {
            widget.onUpdate(
              widget.task.copyWith(title: text),
            );
            // Defer adding new task until after the frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onAddTask();
            });
          } else {
            // Defer deleting the task until after the frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onDelete();
            });
          }
        },
      ),
      trailing: ReorderableDragStartListener(
        index: widget.index,
        child: Icon(Icons.drag_handle),
      ),
    );
  }
}
