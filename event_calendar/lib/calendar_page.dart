import 'package:event_calendar/models/event.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'models/calendar_data.dart';

DateTime minCalendarDate = DateTime.utc(1,1,1);
DateTime maxCalendarDate = DateTime.utc(9999,12,31);

class CalendarPage extends StatefulWidget {
  final CalendarData calendar;

  final Future<void> Function()? onChanged;

  const CalendarPage({
    super.key,
    required this.calendar,
    this.onChanged,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime focusedDay = DateTime.utc(2026,1,1);
  DateTime? selectedDay;

  // Text controllers
  TextEditingController newEventTitleTEC = TextEditingController();
  TextEditingController newEventDescriptionTEC = TextEditingController();

  Future<void> addEvent(Event event) async {
    final day = normalizeDate(event.start);

    setState(() {
      widget.calendar.events.putIfAbsent(day, () => []);
      widget.calendar.events[day]!.add(event);
    });

    await widget.onChanged?.call();
  }

  void deleteEvent(DateTime day, Event event) async {
    setState(() {
      widget.calendar.events[day]?.remove(event);

      if (widget.calendar.events[day]?.isEmpty ?? false) {
        widget.calendar.events.remove(day);
      }
    });

    await widget.onChanged?.call();
  }

  void editEvent(DateTime oldDay, Event event) {
    final titleController = TextEditingController(text: event.title);
    final descController = TextEditingController(text: event.description);
    DateTime selectedDate = event.start;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Event"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Title"),
                  ),
                  TextField(
                    controller: descController,
                    keyboardType: TextInputType.multiline,
                    minLines: 3,
                    maxLines: null,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Date: ${selectedDate.toLocal().toString().split(' ')[0]}",
                        ),
                      ),
                      TextButton(
                        child: const Text("Change"),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: minCalendarDate,
                            lastDate: maxCalendarDate,
                            initialDate: selectedDate,
                          );

                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    final newEvent = Event(
                      title: titleController.text,
                      description: descController.text,
                      start: selectedDate,
                      end: selectedDate,
                    );

                    // remove old
                    widget.calendar.events[oldDay]?.remove(event);

                    if (widget.calendar.events[oldDay]?.isEmpty ?? false) {
                      widget.calendar.events.remove(oldDay);
                    }

                    // add new
                    final newDay = normalizeDate(selectedDate);
                    widget.calendar.events.putIfAbsent(newDay, () => []);
                    widget.calendar.events[newDay]!.add(newEvent);

                    setState(() {});

                    await widget.onChanged?.call();

                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Event> getEventsForDay(DateTime day){
    return widget.calendar.events[normalizeDate(day)] ?? [];
  }

  List<EventUI> renderEventsForDay(List<Event> events, Color eventBackColor){
    List<EventUI> response = [];
    for(var i=0; i<events.length; i++){
      Color color = (i%2==0 ? eventBackColor : changeColorLightness(eventBackColor, -0.05));
      final event = events[i];
      final day = normalizeDate(event.start);

      response.add(
        EventUI(
          event,
          () => editEvent(day, event),
          () => deleteEvent(day, event),
          color,
        ),
      );
    }
    return response;
  }

  Color changeColorLightness(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }

  void _openSearch() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            List<MapEntry<DateTime, Event>> results = [];

            void runSearch(String query) {
              final q = query.toLowerCase();

              final allEvents = widget.calendar.events.entries.expand(
                (entry) => entry.value.map(
                  (event) => MapEntry(entry.key, event),
                ),
              );

              results = allEvents.where((e) {
                final event = e.value;
                return event.title.toLowerCase().contains(q) ||
                      event.description.toLowerCase().contains(q);
              }).toList();

              setStateDialog(() {});
            }

            runSearch(controller.text);

            return AlertDialog(
              title: const Text("Search Events"),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Search title or description",
                      ),
                      onChanged: runSearch,
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final entry = results[index];
                          final date = entry.key;
                          final event = entry.value;

                          return ListTile(
                            title: Text(event.title),
                            subtitle: Text(
                              "${event.description}\n${date.toLocal().toString().split(' ')[0]}",
                            ),
                            onTap: () {
                              setState(() {
                                focusedDay = date;
                                selectedDay = date;
                              });

                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    newEventTitleTEC.dispose();
    newEventDescriptionTEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.calendar.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Search events",
            onPressed: _openSearch,
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: "Go to date",
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: minCalendarDate,
                lastDate: maxCalendarDate,
                initialDate: focusedDay,
              );

              if (picked != null) {
                setState(() {
                  focusedDay = picked;
                  selectedDay = picked;
                });
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Calendar
            TableCalendar<Event>(
              shouldFillViewport: false,
              firstDay: minCalendarDate,
              lastDay: maxCalendarDate,
              focusedDay: focusedDay,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month'
              },
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) =>
                  isSameDay(selectedDay, day),
              calendarStyle: CalendarStyle(todayDecoration: BoxDecoration(), todayTextStyle: TextStyle()),

              eventLoader: getEventsForDay,

              onDaySelected: (selected, focused) {
                setState(() {
                  selectedDay = selected;

                  if (focused.isBefore(minCalendarDate)) {
                    focusedDay = DateTime.utc(2020, 1, 1);
                  } else if (focused.isAfter(maxCalendarDate)) {
                    focusedDay = DateTime.utc(2030, 12, 31);
                  } else {
                    focusedDay = focused;
                  }
                });
              },
            ),
            // Divider
            SizedBox(height: 4, child: Container(decoration: BoxDecoration(color:  Color.fromARGB(255, 180, 180, 180)))),
            // Event list for selectedDay
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Color.fromARGB(255, 240, 240, 240)),
                child: ListView(
                  children: renderEventsForDay(getEventsForDay(selectedDay ?? focusedDay), Theme.of(context).colorScheme.inversePrimary),
                )
              )
            ),
            // Action buttons
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  spacing: 2.0,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(), // To force Column to fill the space horizontally
                    Padding(
                      padding: EdgeInsets.all(16), 
                      child: TextField(
                        controller: newEventTitleTEC,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Event Title"
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16), 
                      child: TextField(
                        controller: newEventDescriptionTEC,
                        keyboardType: TextInputType.multiline,
                        minLines: 3,
                        maxLines: null,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Event Description",
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        if(selectedDay != null && newEventTitleTEC.text.isNotEmpty && newEventDescriptionTEC.text.isNotEmpty){
                          addEvent(Event( title: newEventTitleTEC.text, description: newEventDescriptionTEC.text, start: selectedDay!, end: selectedDay!));
                          newEventTitleTEC.clear();
                          newEventDescriptionTEC.clear();
                        }
                      }, 
                      child: Text("Add Event")
                    )
                  ],
                ),
              )
            )
            
          ],
        )
      )
    );
  }
}


DateTime normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}