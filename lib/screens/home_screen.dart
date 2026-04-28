import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../widgets/task_list_item.dart';
import 'add_task_screen.dart';
import 'settings_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final DateFormat _headerDateFormat = DateFormat('d MMMM yyyy, EEEE', 'tr_TR');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  Future<void> _refreshTasks({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    final tasks = await DatabaseHelper.instance.readAllTasks();
    setState(() {
      _tasks = tasks;
      if (showLoading) _isLoading = false;
    });
  }

  Future<void> _toggleTaskStatus(Task task) async {
    // Local widget handles UI update. We just update data locally and in DB.
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
    }

    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await DatabaseHelper.instance.update(updatedTask);
    
    if (updatedTask.isCompleted) {
      if (updatedTask.id != null) {
        await NotificationService().cancelTaskNotifications(updatedTask.id!);
      }
    } else if (updatedTask.date.isAfter(DateTime.now())) {
      await NotificationService().scheduleTaskNotifications(
        id: updatedTask.id ?? 0,
        title: updatedTask.title,
        body: updatedTask.description,
        scheduledDate: updatedTask.date,
      );
    }
  }

  Future<void> _deleteTask(int id) async {
    await DatabaseHelper.instance.delete(id);
    await NotificationService().cancelTaskNotifications(id);
    _refreshTasks(showLoading: false);
  }

  String _formatDateHeader(DateTime date) {
    return _headerDateFormat.format(date);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Consumer<SettingsService>(
                builder: (context, settings, child) {
                  return Text(
                    settings.appTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                    ),
                  );
                },
              ),
              background: Consumer<SettingsService>(
                builder: (context, settings, child) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          settings.themeColor.withOpacity(0.5),
                          BlendMode.srcATop,
                        ),
                        child: Image.asset(
                          'assets/images/header_bg.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Dark gradient overlay for better text readability
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black45],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_tasks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              blurRadius: 40,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.asset(
                            'assets/images/empty_state.png',
                            width: 250,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Bomboş bir sayfa!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bugün için planladığın tüm harika işleri buraya eklemeye başla.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 40), // Spacing for FAB
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = _tasks[index];
                    bool showDateHeader = false;
                    if (index == 0) {
                      showDateHeader = true;
                    } else {
                      final previousTask = _tasks[index - 1];
                      if (!_isSameDay(task.date, previousTask.date)) {
                        showDateHeader = true;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateHeader)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatDateHeader(task.date),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        TaskListItem(
                          task: task,
                          timeFormat: _timeFormat,
                          onToggle: () => _toggleTaskStatus(task),
                          onDelete: () => _deleteTask(task.id!),
                          onEdit: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AddTaskScreen(task: task),
                              ),
                            );
                            if (result == true) {
                              _refreshTasks();
                            }
                          },
                        ),
                      ],
                    );
                  },
                  childCount: _tasks.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddTaskScreen(),
            ),
          );
          if (result == true) {
            _refreshTasks();
          }
        },
        elevation: 6,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const FaIcon(FontAwesomeIcons.plus, size: 20),
        label: const Text('Yeni Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
