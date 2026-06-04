// Platform-conditional CSV download.
// Web  → triggers browser file download via dart:html.
// Other → writes to temp dir and opens the OS share sheet.
export 'csv_download_stub.dart'
    if (dart.library.html) 'csv_download_web.dart';
