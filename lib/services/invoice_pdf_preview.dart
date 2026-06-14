import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../models/invoice_model.dart';
import '../services/invoice_pdf_cache.dart';
import '../services/invoice_pdf_service.dart';

class InvoicePdfPreview extends StatefulWidget {
  final Invoice invoice;

  const InvoicePdfPreview({super.key, required this.invoice});

  @override
  State<InvoicePdfPreview> createState() => _InvoicePdfPreviewState();
}

class _InvoicePdfPreviewState extends State<InvoicePdfPreview> {
  @override
  Widget build(BuildContext context) {
    final invoiceId = widget.invoice.invoiceId;

    if (pdfCache.containsKey(invoiceId)) {
      return SfPdfViewer.memory(
        pdfCache[invoiceId]!,
        pageLayoutMode: PdfPageLayoutMode.continuous,
        scrollDirection: PdfScrollDirection.vertical,
        canShowPaginationDialog: false,
        canShowScrollHead: false,
        enableDoubleTapZooming: true,
      );
    }

    return FutureBuilder<Uint8List>(
      future: InvoicePdfService.generatePdfBytes(widget.invoice),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Failed to load PDF\n${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No PDF found'));
        }

        pdfCache[invoiceId] = snapshot.data!;

        return SfPdfViewer.memory(
          snapshot.data!,
          pageLayoutMode: PdfPageLayoutMode.single,
          scrollDirection: PdfScrollDirection.vertical,
          canShowPaginationDialog: false,
          canShowScrollHead: false,
          enableDoubleTapZooming: true,
        );
      },
    );
  }
}
