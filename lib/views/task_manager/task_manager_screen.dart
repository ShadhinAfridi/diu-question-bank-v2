import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../viewmodels/task_manager_viewmodel.dart';
import '../widgets/premium_task_card.dart'; // Assuming a premium card widget
import '../widgets/state_indicators.dart'; // For empty/error/loading widgets

/// A premium, feature-rich screen for managing study tasks.
///
/// Key Improvements:
/// - **Modern Layout:** Uses a `NestedScrollView` and `SliverAppBar` for a
///   professional scrolling experience where the app bar and tabs collapse smoothly.
/// - **Robust State Handling:** Explicitly handles `loading`, `success`, and `error`
///   states from the ViewModel, providing clear feedback to the user.
/// - **Polished "Add/Edit Task" UI:** Replaces the basic `AlertDialog` with a
///   full-screen modal bottom sheet (`_TaskEditorModal`), which feels more
///   premium and provides more space for form elements.
/// - **Modular & Clean:** The UI is broken down into smaller, well-defined
///   private widgets (`_TaskList`, `_TaskEditorModal`, etc.), making the code
///   easier to read and maintain.
class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key});

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<TaskStatus> _tabs = [TaskStatus.ongoing, TaskStatus.upcoming, TaskStatus.completed];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Use addPostFrameCallback to ensure the ViewModel is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskManagerViewModel>(context, listen: false).refreshTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTaskEditor({Task? task}) {
    final viewModel = Provider.of<TaskManagerViewModel>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskEditorModal(
        viewModel: viewModel,
        task: task,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('My Study Plan'),
              pinned: true,
              floating: true,
              forceElevated: innerBoxIsScrolled,
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded),
                  onPressed: () { /* TODO: Implement Filter Bottom Sheet */ },
                  tooltip: 'Filter Tasks',
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: () { /* TODO: Implement More Options */ },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: _tabs.map((status) => Tab(text: status.displayName.toUpperCase())).toList(),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map((status) {
            return _TaskList(
              status: status,
              key: ValueKey(status),
              onEditTask: (task) => _showTaskEditor(task: task),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
        tooltip: 'Add a new task',
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final TaskStatus status;
  final ValueChanged<Task> onEditTask;

  const _TaskList({super.key, required this.status, required this.onEditTask});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskManagerViewModel>(
      builder: (context, viewModel, child) {
        // Handle different view states
        switch (viewModel.status) {
          case ViewStatus.loading:
            return const CenteredLoadingIndicator();
          case ViewStatus.error:
            return ErrorDisplay(
              message: viewModel.errorMessage,
              onRetry: viewModel.refreshTasks,
            );
          case ViewStatus.success:
            final tasks = viewModel.getTasksByStatus(status);
            if (tasks.isEmpty) {
              return EmptyState(
                icon: Icons.check_circle_outline_rounded,
                message: 'No ${status.displayName.toLowerCase()} tasks yet!',
                details: 'Tap the "+" button to add a new task.',
              );
            }
            return RefreshIndicator(
              onRefresh: viewModel.refreshTasks,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88), // Padding for FAB
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return PremiumTaskCard(
                    task: task,
                    onCompleted: (_) => viewModel.toggleTaskCompletion(task),
                    onTap: () => onEditTask(task),
                    onDelete: () => viewModel.deleteTask(task.id!),
                  );
                },
              ),
            );
        }
      },
    );
  }
}


/// A full-screen modal bottom sheet for creating and editing tasks.
class _TaskEditorModal extends StatefulWidget {
  final TaskManagerViewModel viewModel;
  final Task? task;

  const _TaskEditorModal({required this.viewModel, this.task});

  @override
  _TaskEditorModalState createState() => _TaskEditorModalState();
}

class _TaskEditorModalState extends State<_TaskEditorModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  late Priority _selectedPriority;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _selectedDate = t?.dueDate ?? DateTime.now();
    _selectedTime = t?.time != null ? TimeOfDay.fromDateTime(t!.time!) : null;
    _selectedPriority = t?.priority ?? Priority.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    DateTime? finalDateTime;
    if (_selectedTime != null) {
      final t = _selectedTime!;
      final d = _selectedDate;
      finalDateTime = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    }

    final taskToSave = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _selectedDate,
      priority: _selectedPriority,
      time: finalDateTime,
      isCompleted: widget.task?.isCompleted ?? false,
    );

    if (widget.task == null) {
      widget.viewModel.addTask(taskToSave);
    } else {
      widget.viewModel.updateTask(taskToSave);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNewTask = widget.task == null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(isNewTask ? 'Create New Task' : 'Edit Task'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Task Title'),
                    validator: (v) => v!.trim().isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description (Optional)'),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  _buildDateTimePicker(),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<Priority>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: Priority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.displayName))).toList(),
                    onChanged: (v) => setState(() => _selectedPriority = v!),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _saveTask,
              label: Text(isNewTask ? 'Create Task' : 'Save Changes'),
              icon: const Icon(Icons.save_rounded),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          ),
        );
      },
    );
  }

  Widget _buildDateTimePicker() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Due Date', border: OutlineInputBorder()),
              child: Text(DateFormat.yMMMd().format(_selectedDate)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _selectedTime ?? TimeOfDay.now());
              if (picked != null) setState(() => _selectedTime = picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Time',
                border: const OutlineInputBorder(),
                suffixIcon: _selectedTime != null ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _selectedTime = null)) : null,
              ),
              child: Text(_selectedTime?.format(context) ?? 'Not Set'),
            ),
          ),
        ),
      ],
    );
  }
}
