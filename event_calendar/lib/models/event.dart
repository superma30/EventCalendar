import 'package:flutter/material.dart';

class Event {
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;

  Event({
    required this.title,
    required this.description,
    required this.start,
    required this.end,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      title: json['title'],
      description: json['description'],
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    };
  }

  @override
  String toString() => title;
}

class EventUI extends StatefulWidget{
  final Event event;
  final Color color;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  EventUI(
    this.event,
    this.onEdit,
    this.onDelete,
    [this.color = const Color.fromARGB(0,0,0,0)]
);

  @override
  State<EventUI> createState() => _EventUIState();
}

class _EventUIState extends State<EventUI> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.color,
      child: Padding(
        padding: EdgeInsetsGeometry.directional(start: 10, end: 10), 
        child: Row(
          children: [
            Text(widget.event.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
            SizedBox(width: 10,),
            Expanded(child: Text(widget.event.description, style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),)),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == "edit") widget.onEdit();
                if (value == "delete") widget.onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: "edit", child: Text("Edit")),
                const PopupMenuItem(value: "delete", child: Text("Delete")),
              ],
            )
          ],
        )
      )
    );
  }
}