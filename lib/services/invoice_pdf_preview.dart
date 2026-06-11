import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../models/invoice_model.dart';
import '../services/invoice_pdf_service.dart';

class InvoicePdfPreview extends StatelessWidget {
  final Invoice invoice;

  const InvoicePdfPreview({
    super.key,
    required this.invoice,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: InvoicePdfService.generatePdfBytes(invoice),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load PDF\n${snapshot.error}',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text('No PDF found'),
          );
        }

        return SfPdfViewer.memory(
          snapshot.data!,

          pageLayoutMode: PdfPageLayoutMode.single,

          scrollDirection: PdfScrollDirection.horizontal,

          canShowPaginationDialog: false,

          canShowScrollHead: false,

          enableDoubleTapZooming: true,
        );
      },
    );
  }
}