import 'package:flutter/foundation.dart' show kIsWeb;

// Use environment-aware API URL
final String apiBaseUrl = kIsWeb 
  ? const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://6208df89-04bf-456d-bcf3-a2cac4c6dd00.mock.pstmn.io')
  : const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://192.168.1.140:8000');

const bool useDummyData = false; // Set to false for production