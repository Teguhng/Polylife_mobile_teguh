import 'dart:typed_data';

import 'pdf_download_stub.dart'
    if (dart.library.html) 'pdf_download_web.dart'
    as platform;

Future<void> downloadPdfBytes(Uint8List bytes, String filename) =>
    platform.downloadPdfBytes(bytes, filename);
