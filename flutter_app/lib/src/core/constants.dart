import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Use a runtime getter so .env values loaded in main.dart are respected.
String get apiBaseUrl =>
    dotenv.env['API_BASE_URL']?.trim() ?? 'http://192.168.1.140:8000';
