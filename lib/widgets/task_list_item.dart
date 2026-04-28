import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskListItem extends StatefulWidget {
  final Task task;
  final DateFormat timeFormat;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TaskListItem({
    Key? key,
    required this.task,
    required this.timeFormat,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.task.isCompleted;
  }

  @override
  void didUpdateWidget(covariant TaskListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.isCompleted != widget.task.isCompleted) {
      _isCompleted = widget.task.isCompleted;
    }
  }

  void _handleToggle() {
    setState(() {
      _isCompleted = !_isCompleted;
    });
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Dismissible(
        key: Key('${widget.task.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5252),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5252).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const FaIcon(FontAwesomeIcons.trashCan, color: Colors.white, size: 28),
        ),
        onDismissed: (direction) => widget.onDelete(),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isCompleted ? 0.6 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _handleToggle,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isCompleted
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey.shade400,
                                width: 2.5,
                              ),
                              color: _isCompleted
                                  ? const Color(0xFF4CAF50)
                                  : Colors.transparent,
                              boxShadow: _isCompleted
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF4CAF50).withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : null,
                            ),
                            child: _isCompleted
                                ? const Icon(Icons.check, size: 20, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.task.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: _isCompleted ? FontWeight.normal : FontWeight.w600,
                                  decoration: _isCompleted ? TextDecoration.lineThrough : null,
                                  color: _isCompleted ? Colors.grey.shade600 : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              if (widget.task.description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  widget.task.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    decoration: _isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(FontAwesomeIcons.clock, size: 12, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                widget.timeFormat.format(widget.task.date),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
