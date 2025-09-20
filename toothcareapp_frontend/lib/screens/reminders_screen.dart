import 'package:flutter/material.dart';
import '../services/reminder_store.dart';
import '../services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Reminder> _reminders = [];

  // Simple filter: all | on | off
  String _filter = 'all';
  bool _notifEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final ok = await NotificationService.areNotificationsEnabled();
    if (mounted) setState(() => _notifEnabled = ok);
  }

  Future<void> _load() async {
    final list = await ReminderStore.load();
    // Sort by time ascending for stable order
    list.sort((a, b) {
      final aa = a.hour * 60 + a.minute;
      final bb = b.hour * 60 + b.minute;
      return aa.compareTo(bb);
    });
    setState(() => _reminders = list);
  }

  Future<void> _toggle(Reminder r, bool enabled) async {
    await ReminderStore.toggle(r.id, enabled);
    await _load();
  }

  Future<void> _delete(Reminder r) async {
    await ReminderStore.remove(r.id);
    await _load();
  }

  Future<void> _showEditor({Reminder? existing}) async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    TimeOfDay time = existing != null
        ? TimeOfDay(hour: existing.hour, minute: existing.minute)
        : TimeOfDay.now();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'Add Reminder' : 'Edit Reminder',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title / Notes',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter a title'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatefulBuilder(
                        builder: (context, setTimeState) {
                          return OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(time.format(context)),
                            onPressed: () async {
                              final res = await showTimePicker(
                                context: context,
                                initialTime: time,
                              );
                              if (res != null) {
                                time = res;
                                setTimeState(() {});
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setModalState) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: saving 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                        label: Text(saving ? 'Saving...' : (existing == null ? 'Save' : 'Update')),
                        onPressed: saving ? null : () async {
                          if (!formKey.currentState!.validate()) return;
                          
                          setModalState(() => saving = true);
                          
                          final title = titleCtrl.text.trim();
                          // Ensure we have permissions before scheduling
                          final hasPerm = await NotificationService.ensurePermissions();
                          if (existing == null) {
                            final r = Reminder.newFor(
                              title: title,
                              hour: time.hour,
                              minute: time.minute,
                            );
                            await ReminderStore.add(r);
                          } else {
                            final updated = Reminder(
                              id: existing.id,
                              title: title,
                              hour: time.hour,
                              minute: time.minute,
                              enabled: existing.enabled,
                            );
                            await ReminderStore.update(updated);
                          }
                          
                          if (!mounted) return;
                          Navigator.of(ctx).pop();
                          await _load(); // Refresh the list immediately
                          if (!hasPerm) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Notification permission not granted — reminders may not fire.')), 
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(existing == null ? 'Reminder added (daily)' : 'Reminder updated')),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reminders'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'test') {
                try {
                  await NotificationService.scheduleInSeconds(
                    id: DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
                    seconds: 10,
                    title: 'Test Reminder',
                    body: 'This is a 10s test notification',
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test notification scheduled in 10s')),
                  );
                } catch (e) {
                  final msg = e.toString();
                  if (msg.contains('exact_alarms_not_permitted')) {
                    final go = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Allow Exact Alarms'),
                        content: const Text('Your device is blocking exact alarms. Allow "Alarms & reminders" access to let scheduled reminders fire on time.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open Settings')),
                        ],
                      ),
                    );
                    if (go == true) {
                      await NotificationService.requestExactAlarmsPermission();
                    }
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to schedule: $e')),
                    );
                  }
                }
              } else if (v == 'show_now') {
                await NotificationService.showNow(
                  id: DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
                  title: 'Immediate Test',
                  body: 'This should appear instantly',
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Immediate notification shown')),
                );
              } else if (v == 'enable_all') {
                for (final r in _reminders.where((e) => !e.enabled)) {
                  await ReminderStore.toggle(r.id, true);
                }
                await _load();
              } else if (v == 'disable_all') {
                for (final r in _reminders.where((e) => e.enabled)) {
                  await ReminderStore.toggle(r.id, false);
                }
                await _load();
              } else if (v == 'pending') {
                final list = await NotificationService.pending();
                if (!mounted) return;
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Pending Notifications'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: SingleChildScrollView(
                        child: Text(list.isEmpty
                            ? 'None'
                            : list
                                .map((p) => 'id=${p.id} title="${p.title}" body="${p.body}"')
                                .join('\n')),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      )
                    ],
                  ),
                );
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem<String>(value: 'test', child: Text('Test notification (10s)')),
              PopupMenuItem<String>(value: 'show_now', child: Text('Show immediate notification')),
              PopupMenuItem<String>(value: 'enable_all', child: Text('Enable all')),
              PopupMenuItem<String>(value: 'disable_all', child: Text('Disable all')),
              PopupMenuItem<String>(value: 'pending', child: Text('Show pending schedules')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditor(),
            tooltip: 'Add Reminder',
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_notifEnabled)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_off, color: Colors.deepOrange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Notifications are disabled. Enable permissions to receive reminders.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final granted = await NotificationService.ensurePermissions();
                      if (mounted) setState(() => _notifEnabled = granted);
                    },
                    child: const Text('Enable'),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await NotificationService.scheduleInSeconds(
                          id: DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
                          seconds: 5,
                          title: 'Reminder Test',
                          body: 'If you receive this, notifications work.',
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Test scheduled in 5s')),
                        );
                      } catch (e) {
                        final msg = e.toString();
                        if (msg.contains('exact_alarms_not_permitted')) {
                          final go = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Allow Exact Alarms'),
                              content: const Text('Your device is blocking exact alarms. Allow "Alarms & reminders" access to let scheduled reminders fire on time.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open Settings')),
                              ],
                            ),
                          );
                          if (go == true) {
                            await NotificationService.requestExactAlarmsPermission();
                          }
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to schedule: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Test'),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == 'all',
                  onSelected: (_) => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('On'),
                  selected: _filter == 'on',
                  onSelected: (_) => setState(() => _filter = 'on'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Off'),
                  selected: _filter == 'off',
                  onSelected: (_) => setState(() => _filter = 'off'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _reminders.isEmpty
                ? const Center(child: Text('No reminders yet. Tap + to add.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: _filteredReminders.length,
                    itemBuilder: (ctx, i) {
                      final r = _filteredReminders[i];
                      final time = TimeOfDay(hour: r.hour, minute: r.minute);
                      final timeLabel = time.format(context);
                      final on = r.enabled;
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => _showEditor(existing: r),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: on ? const Color(0xFFE8F5E9) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: on ? const Color(0xFF22B573) : Colors.grey.shade300),
                            ),
                            child: Center(
                              child: Text(
                                _compactTime(timeLabel),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: on ? const Color(0xFF22B573) : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                          title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('Every day at $timeLabel'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => _toggle(r, !on),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: on ? const Color(0xFF22B573) : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    on ? 'On' : 'Off',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditor(existing: r),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (dCtx) => AlertDialog(
                                      title: const Text('Delete reminder?'),
                                      content: const Text('This will remove the reminder and its schedule.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                                        ElevatedButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _delete(r);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Reminder deleted')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Reminder> get _filteredReminders {
    if (_filter == 'on') return _reminders.where((e) => e.enabled).toList();
    if (_filter == 'off') return _reminders.where((e) => !e.enabled).toList();
    return _reminders;
  }

  String _compactTime(String formatted) {
    // Convert like "8:30 AM" -> "8:30" for avatar
    final parts = formatted.split(' ');
    return parts.first;
  }
}
