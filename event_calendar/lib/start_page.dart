import 'package:flutter/material.dart';
import 'models/calendar_data.dart';
import 'calendar_page.dart';
import 'storage_service.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final TextEditingController calendarNameController =
      TextEditingController();

  List<CalendarData> calendars = [];

  Future<void> createCalendar() async {
    if (calendarNameController.text.isEmpty) return;

    final calendar = CalendarData(
      name: calendarNameController.text,
    );

    setState(() {
      calendars.add(calendar);
    });

    await StorageService.saveCalendars(calendars);

    calendarNameController.clear();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CalendarPage(
          calendar: calendar,
          onChanged: () =>
              StorageService.saveCalendars(calendars),
        ),
      ),
    );
  }

  void openCalendar(CalendarData calendar) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CalendarPage(
          calendar: calendar,
          onChanged: () =>
              StorageService.saveCalendars(calendars),
        ),
      ),
    );
  }

  void renameCalendar(CalendarData calendar) {
    final controller = TextEditingController(text: calendar.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rename Calendar"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    calendar.name = controller.text;
                  });

                  await StorageService.saveCalendars(calendars);
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void deleteCalendar(CalendarData calendar) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Calendar"),
          content: Text(
            'Delete "${calendar.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  calendars.remove(calendar);
                });

                await StorageService.saveCalendars(calendars);

                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    loadCalendars();
  }

  Future<void> loadCalendars() async {
    final loaded = await StorageService.loadCalendars();

    setState(() {
      calendars = loaded;
    });
  }

  Future<void> importCalendar() async {
    final imported = await StorageService.importCalendar();

    if (imported == null) return;

    setState(() {
      calendars.add(imported);
    });

    await StorageService.saveCalendars(calendars);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendars"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: calendarNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Calendar Name",
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: createCalendar,
                    child: const Text("Create Calendar"),
                  ),
                ),

                const SizedBox(width: 10),

                IconButton(
                  tooltip: "Import JSON",
                  icon: const Icon(Icons.upload_file),
                  onPressed: importCalendar,
                ),
              ],
            ),

            const Divider(),

            Expanded(
              child: ListView.builder(
                itemCount: calendars.length,
                itemBuilder: (context, index) {
                  final calendar = calendars[index];

                  return ListTile(
                    title: Text(calendar.name),

                    onTap: () => openCalendar(calendar),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download),
                          tooltip: "Export",
                          onPressed: () async {
                            await StorageService.exportCalendar(calendar);
                          },
                        ),

                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: "Rename",
                          onPressed: () => renameCalendar(calendar),
                        ),

                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: "Delete",
                          onPressed: () => deleteCalendar(calendar),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}