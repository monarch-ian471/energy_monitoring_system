import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Use a runtime getter so .env values loaded in main.dart are respected.
String get apiBaseUrl =>
    dotenv.env['API_BASE_URL']?.trim() ?? 'http://192.168.1.140:8000';

/// Build a safe Uri for API endpoints using the configured base URL.
Uri buildApiUri(String relativePath, [Map<String, String>? queryParameters]) {
    var base = dotenv.env['API_BASE_URL']?.trim() ?? 'http://192.168.1.140:8000';
    // Tolerate common accidental typos like `htto://` and missing scheme.
    if (base.startsWith('htto://')) base = base.replaceFirst('htto://', 'http://');
    if (!base.startsWith('http://') && !base.startsWith('https://')) {
        base = 'http://' + base;
    }

    final baseUri = Uri.parse(base);

    // Normalize paths and join base path + relative path.
    final rp = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
    final bp = baseUri.path.startsWith('/') ? baseUri.path.substring(1) : baseUri.path;
    final combined = [if (bp.isNotEmpty) bp, if (rp.isNotEmpty) rp].join('/');

    return Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.hasPort ? baseUri.port : null,
        path: combined,
        queryParameters: queryParameters,
    );
}

/// Get HTTP headers including ngrok bypass header
/// This is required to skip ngrok's interstitial warning page on free tier
Map<String, String> getApiHeaders() {
    return {
        'ngrok-skip-browser-warning': 'true',
        'Content-Type': 'application/json',
    };
}
