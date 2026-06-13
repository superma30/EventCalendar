import 'event.dart';

class CalendarData {
  String name;
  Map<DateTime, List<Event>> events;

  CalendarData({
    required this.name,
    Map<DateTime, List<Event>>? events,
  }) : events = events ?? {};

  factory CalendarData.fromJson(Map<String, dynamic> json) {
    final Map<DateTime, List<Event>> loadedEvents = {};

    final rawEvents = json['events'] as Map<String, dynamic>;

    rawEvents.forEach((dateString, eventList) {
      loadedEvents[DateTime.parse(dateString)] =
          (eventList as List)
              .map((e) => Event.fromJson(e))
              .toList();
    });

    return CalendarData(
      name: json['name'],
      events: loadedEvents,
    );
  }

  Map<String, dynamic> toJson() {
    final eventMap = <String, dynamic>{};

    events.forEach((date, eventList) {
      eventMap[date.toIso8601String()] =
          eventList.map((e) => e.toJson()).toList();
    });

    return {
      'name': name,
      'events': eventMap,
    };
  }
}