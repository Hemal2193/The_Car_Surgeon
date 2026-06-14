import 'dart:typed_data';

final Map<String, Uint8List> pdfCache = {};

void invalidatePdfCache(String invoiceId) {
  pdfCache.remove(invoiceId);
}
