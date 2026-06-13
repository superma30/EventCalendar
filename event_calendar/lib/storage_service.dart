import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/calendar_data.dart';

class StorageService {
  static const String fileName = "calendars.json";
  static const String webKey = "calendars";

  static Future<void> saveCalendars(List<CalendarData> calendars) async {
    final jsonData =
        jsonEncode(calendars.map((c) => c.toJson()).toList());

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(webKey, jsonData);
      return;
    }

    final file = await _getFile();
    await file.writeAsString(jsonData);
  }

  static Future<List<CalendarData>> loadCalendars() async {
    try {
      String? content;

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        content = prefs.getString(webKey);
      } else {
        final file = await _getFile();

        if (!await file.exists()) {
          return [];
        }

        content = await file.readAsString();
      }

      if (content == null || content.isEmpty) {
        return [];
      }

      final decoded = jsonDecode(content) as List;

      return decoded
          .map((e) => CalendarData.fromJson(e))
          .toList();
    } catch (e) {
      print("Storage error: $e");
      return [];
    }
  }

  static Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();

    return File("${directory.path}/$fileName");
  }

  static Future<String> exportCalendarsJson(List<CalendarData> calendars) async {
    return jsonEncode(calendars.map((c) => c.toJson()).toList());
  }

  static Future<void> exportCalendar(CalendarData calendar) async {
    final jsonString = jsonEncode(calendar.toJson());

    final bytes = Uint8List.fromList(jsonString.codeUnits);

    final file = XFile.fromData(
      bytes,
      name: "${calendar.name}.json",
      mimeType: "application/json",
    );

    await Share.shareXFiles([file]);
  }

  static Future<CalendarData?> importCalendar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final fileBytes = result.files.first.bytes;
    if (fileBytes == null) return null;

    final content = utf8.decode(fileBytes);

    final decoded = jsonDecode(content);

    return CalendarData.fromJson(decoded);
  }
}