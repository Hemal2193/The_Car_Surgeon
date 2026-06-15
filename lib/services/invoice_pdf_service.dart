// ignore_for_file: deprecated_member_use

import 'package:flutter/services.dart' show rootBundle, MethodChannel;
import 'package:get/get.dart';
import 'package:number_to_words_english/number_to_words_english.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tcs/controllers/customer_controller.dart';
import 'package:tcs/controllers/vehicle_controller.dart';
import 'package:tcs/controllers/reminder_controller.dart';
import 'package:printing/printing.dart';
import 'package:tcs/models/customer_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/invoice_model.dart';

class InvoicePdfService {
  static Uint8List? _cachedLogo;

  static Future<Uint8List> _getLogo() async {
    if (_cachedLogo != null) return _cachedLogo!;
    try {
      _cachedLogo = (await rootBundle.load(
        'assets/logo.jpeg',
      )).buffer.asUint8List();
    } catch (_) {
      _cachedLogo = Uint8List(0);
    }
    return _cachedLogo!;
  }

  // =====================================================
  // CREATE PDF DOCUMENT
  // =====================================================
  static pw.Document _buildPdfDocument(Invoice invoice, Uint8List logoBytes) {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginBottom: 0,
          marginTop: 0,
          marginLeft: 0,
          marginRight: 0,
        ),

        margin: const pw.EdgeInsets.all(24),

        build: (context) => [
          _buildHeader(invoice, logoBytes),

          pw.SizedBox(height: 20),

          _buildCustomerBlock(invoice),

          pw.SizedBox(height: 20),

          _buildItemsTable(invoice),

          pw.SizedBox(height: 20),

          _buildTaxSummaryTable(invoice),

          pw.SizedBox(height: 20),

          _buildAmountInWords(invoice),

          pw.SizedBox(height: 20),

          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(),
              1: const pw.FixedColumnWidth(20),
              2: const pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(
                verticalAlignment: pw.TableCellVerticalAlignment.full,
                children: [
                  _buildBankDetails(),
                  pw.SizedBox(),
                  _buildSignature(),
                ],
              ),
            ],
          ),
        ],

        footer: (context) => _buildFooter(),
      ),
    );

    return pdf;
  }

  // =====================================================
  // PDF BYTES (FOR PREVIEW)
  // =====================================================
  static Future<Uint8List> generatePdfBytes(Invoice invoice) async {
    final logoBytes = await _getLogo();
    final pdf = _buildPdfDocument(invoice, logoBytes);

    return pdf.save();
  }

  // =====================================================
  // SHARE PDF (uses share_plus for mobile, printing for desktop)
  // =====================================================
  static Future<void> shareInvoicePdf(
    Invoice invoice, {
    bool isMobile = false,
  }) async {
    final bytes = await generatePdfBytes(invoice);

    if (isMobile) {
      // Write to temp file, then share via share_plus
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/${invoice.invoiceId}.pdf');
      await tempFile.writeAsBytes(bytes);

      await Share.shareXFiles([
        XFile(tempFile.path, mimeType: 'application/pdf'),
      ], subject: 'Invoice ${invoice.invoiceId}');
    } else {
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${invoice.invoiceId}.pdf',
      );
    }
  }

  // =====================================================
  // SHARE VIA WHATSAPP – DESKTOP
  // Saves PDF to Desktop/TCS_Invoices folder,
  // opens WhatsApp Web, and returns the saved file path.
  // =====================================================
  static Future<String?> shareInvoiceViaWhatsApp(
    Invoice invoice,
    Customer? customer,
  ) async {
    final bytes = await generatePdfBytes(invoice);
    final mobileNo = customer?.contact1;

    // Save to Desktop/TCS_Invoices/
    final desktop = Directory(
      '${Platform.environment['USERPROFILE']}\\Desktop',
    );

    final tcsDir = Directory('${desktop.path}\\TCS_Invoices');

    if (!await tcsDir.exists()) {
      await tcsDir.create(recursive: true);
    }

    final pdfFile = File('${tcsDir.path}\\${invoice.invoiceId}.pdf');

    await pdfFile.writeAsBytes(bytes);

    final savedPath = pdfFile.path;

    // Open WhatsApp chat directly
    if (mobileNo != null && mobileNo.trim().isNotEmpty) {
      try {
        final phone = mobileNo.replaceAll(RegExp(r'[^0-9]'), '');

        await Pasteboard.writeFiles([savedPath]);

        await launchUrl(
          Uri.parse('https://wa.me/91$phone'),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        // Ignore errors
      }
    }

    return savedPath;
  }

  // =====================================================
  // DOWNLOAD PDF – DESKTOP (file picker)
  // =====================================================
  static Future<void> generateInvoicePdf(Invoice invoice) async {
    final bytes = await generatePdfBytes(invoice);

    const XTypeGroup pdfTypeGroup = XTypeGroup(
      label: 'PDF',
      extensions: ['pdf'],
    );

    final String? path = await getSaveLocation(
      acceptedTypeGroups: [pdfTypeGroup],
      suggestedName: '${invoice.invoiceId}.pdf',
    ).then((location) => location?.path);

    if (path == null) {
      return;
    }

    final file = File(path);
    await file.writeAsBytes(bytes);
  }

  // =====================================================
  // DOWNLOAD PDF – MOBILE (saves to Downloads/TCS via platform channel)
  // =====================================================
  static const _channel = MethodChannel('com.example.tcs/download');

  static Future<String?> downloadInvoicePdfMobile(Invoice invoice) async {
    final bytes = await generatePdfBytes(invoice);

    final result = await _channel.invokeMethod<String>('saveToDownloads', {
      'fileName': '${invoice.invoiceId}.pdf',
      'fileBytes': bytes,
      'subFolder': 'TCS',
    });

    return result;
  }

  // =====================================================
  // HEADER
  // =====================================================
  static pw.Widget _buildHeader(Invoice invoice, Uint8List logoBytes) {
    final vehicleController = Get.find<VehicleController>();
    final reminderCtrl = Get.find<ReminderController>();

    final vehicle = vehicleController.getVehicleById(invoice.vehicleId);
    final reminder = reminderCtrl.getReminderByInvoiceId(invoice.invoiceId);

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "The Car Surgeon",
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "Laxmipura, Vadodara, Gujarat 390021",
            style: pw.TextStyle(color: PdfColors.grey900, fontSize: 12),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              //Section 1
              pw.Container(
                height: 115,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        decoration: pw.BoxDecoration(
                          color: PdfColors.black,
                          border: pw.Border.all(),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.ClipRRect(
                            horizontalRadius: 4,
                            verticalRadius: 4,
                            child: pw.Image(
                              pw.MemoryImage(logoBytes),
                              width: 70,
                              height: 70,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              // GSTIN Block
                              pw.RichText(
                                text: pw.TextSpan(
                                  children: [
                                    pw.TextSpan(
                                      text: "GSTIN: \n",
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                    pw.TextSpan(
                                      text: "24ABWPW0365P1ZO",
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.normal,
                                        fontSize: 11,
                                        color: PdfColors.grey900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              pw.SizedBox(width: 15),

                              // Contact Block
                              pw.RichText(
                                text: pw.TextSpan(
                                  children: [
                                    pw.TextSpan(
                                      text: "Contact: \n",
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                    pw.TextSpan(
                                      text: "7069779966",
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.normal,
                                        fontSize: 11,
                                        color: PdfColors.grey900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 5),
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: "Pan No: \n",
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                                pw.TextSpan(
                                  text: "ABWPW0365P",
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.normal,
                                    fontSize: 11,
                                    color: PdfColors.grey900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: "Email: \n",
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                                pw.TextSpan(
                                  text: "thecarsurgeonbaroda@gmail.com",
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.normal,
                                    fontSize: 11,
                                    color: PdfColors.grey900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Section 2
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  //invoice card
                  pw.Container(
                    height: 50,
                    width: 240,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      children: [
                        // Labels
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                "Invoice Id",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                "Invoice Date",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                "Due Date",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        pw.SizedBox(height: 4),

                        // Values
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                invoice.invoiceId,
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(fontSize: 9),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                "${invoice.dateTime.day.toString().padLeft(2, '0')}-"
                                "${invoice.dateTime.month.toString().padLeft(2, '0')}-"
                                "${(invoice.dateTime.year % 100).toString().padLeft(2, '0')}",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(fontSize: 9),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                reminder != null
                                    ? "${reminder.dueDate.day.toString().padLeft(2, '0')}-"
                                          "${reminder.dueDate.month.toString().padLeft(2, '0')}-"
                                          "${(reminder.dueDate.year % 100).toString().padLeft(2, '0')}"
                                    : "-",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(fontSize: 9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  //vehicle card
                  pw.Container(
                    height: 55,
                    width: 240,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      children: [
                        // Labels
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                "Vehicle No",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                "Odometer",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                "Model",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        pw.SizedBox(height: 4),

                        // Values
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                vehicle?.registrationNumber ?? "-",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(fontSize: 9),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                "${vehicle?.odoMeter ?? "-"} Km",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(fontSize: 9),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                vehicle == null
                                    ? "-"
                                    : "${vehicle.make} ${vehicle.model}",
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(fontSize: 9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // CUSTOMER BLOCK
  // =====================================================
  static pw.Widget _buildCustomerBlock(Invoice invoice) {
    final customerController = Get.find<CustomerController>();

    final customer = customerController.getCustomerById(invoice.customerId);

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Bill To:",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(100), // Label
                  1: const pw.FixedColumnWidth(15), // Colon
                  2: const pw.FixedColumnWidth(220), // Value
                },
                children: [
                  _buildTableRow("Customer Name", customer?.name),
                  _buildTableRow("Contact", customer?.contact1),
                  _buildTableRow("Address", customer?.address),
                  _buildTableRow("GSTIN", customer?.gstNumber),
                  _buildTableRow("Pan Number", customer?.panNumber),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.TableRow _buildTableRow(String label, dynamic value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(label, style: pw.TextStyle(fontSize: 11)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(":"),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(
            value?.toString() ?? "N/A",
            style: pw.TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // ITEMS TABLE
  // =====================================================
  static pw.Widget _buildItemsTable(Invoice invoice) {
    final totalQty = invoice.items.fold<double>(
      0,
      (sum, item) => sum + item.qty,
    );

    final totalRate = invoice.items.fold<double>(
      0,
      (sum, item) => sum + (item.rate * item.qty),
    );

    final totalTax = invoice.items.fold<double>(
      0,
      (sum, item) => sum + item.taxAmount,
    );

    final totalAmount = invoice.items.fold<double>(
      0,
      (sum, item) => sum + item.totalAmount,
    );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.only(
          topLeft: pw.Radius.circular(4),
          topRight: pw.Radius.circular(4),
          bottomLeft: pw.Radius.circular(4),
          bottomRight: pw.Radius.circular(4),
        ),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 4,
        verticalRadius: 4,
        child: pw.Table.fromTextArray(
          headers: const [
            "Sr",
            "Item",
            "HSN",
            "Qty",
            "Rate",
            "GST %",
            "Tax",
            "Amount",
          ],

          data: [
            ...List.generate(invoice.items.length, (i) {
              final item = invoice.items[i];

              return [
                "${i + 1}",
                item.name,
                item.hsnSac ?? "-",
                item.qty.toString(),
                item.rate.toStringAsFixed(2),
                "${item.taxPercent.toStringAsFixed(0)}%",
                item.taxAmount.toStringAsFixed(2),
                item.totalAmount.toStringAsFixed(2),
              ];
            }),

            [
              "",
              "Total",
              "",
              totalQty.toStringAsFixed(0),
              totalRate.toStringAsFixed(2),
              "",
              totalTax.toStringAsFixed(2),
              totalAmount.toStringAsFixed(2),
            ],
          ],

          border: pw.TableBorder(
            left: const pw.BorderSide(color: PdfColors.grey300),
            right: const pw.BorderSide(color: PdfColors.grey300),
            bottom: const pw.BorderSide(color: PdfColors.grey300),
            horizontalInside: const pw.BorderSide(color: PdfColors.grey300),
            verticalInside: const pw.BorderSide(color: PdfColors.grey300),
          ),

          headerStyle: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),

          headerDecoration: const pw.BoxDecoration(
            color: PdfColors.black,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(4),
              topRight: pw.Radius.circular(4),
            ),
          ),

          cellStyle: const pw.TextStyle(fontSize: 11),

          cellAlignment: pw.Alignment.center,
          headerAlignment: pw.Alignment.center,

          cellDecoration: (index, data, rowNum) {
            if (rowNum == invoice.items.length + 1) {
              return const pw.BoxDecoration(color: PdfColors.grey200);
            }
            return const pw.BoxDecoration();
          },
        ),
      ),
    );
  }

  // =====================================================
  // Tax Summary
  // =====================================================
  static pw.Widget _buildTaxSummaryTable(Invoice invoice) {
    final Map<String, Map<String, double>> summary = {};

    for (final item in invoice.items) {
      final hsn = item.hsnSac ?? "-";

      final taxableValue = item.rate * item.qty;
      final totalTax = item.taxAmount;

      final cgstAmount = totalTax / 2;
      final sgstAmount = totalTax / 2;

      if (!summary.containsKey(hsn)) {
        summary[hsn] = {
          'taxable': 0,
          'cgst': 0,
          'sgst': 0,
          'tax': 0,
          'gstRate': item.taxPercent,
        };
      }

      summary[hsn]!['taxable'] = summary[hsn]!['taxable']! + taxableValue;

      summary[hsn]!['cgst'] = summary[hsn]!['cgst']! + cgstAmount;

      summary[hsn]!['sgst'] = summary[hsn]!['sgst']! + sgstAmount;

      summary[hsn]!['tax'] = summary[hsn]!['tax']! + totalTax;
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 4,
        verticalRadius: 4,
        child: pw.Table.fromTextArray(
          headers: const [
            "HSN/SAC",
            "Taxable Value",
            "CGST Rate",
            "CGST Amount",
            "SGST Rate",
            "SGST Amount",
            "Total Tax Amount",
          ],

          data: summary.entries.map((entry) {
            return [
              entry.key,
              entry.value['taxable']!.toStringAsFixed(2),
              "${(entry.value['gstRate']! / 2).toStringAsFixed(0)}%",
              entry.value['cgst']!.toStringAsFixed(2),
              "${(entry.value['gstRate']! / 2).toStringAsFixed(0)}%",
              entry.value['sgst']!.toStringAsFixed(2),
              entry.value['tax']!.toStringAsFixed(2),
            ];
          }).toList(),

          border: pw.TableBorder(
            left: const pw.BorderSide(color: PdfColors.grey300),
            right: const pw.BorderSide(color: PdfColors.grey300),
            bottom: const pw.BorderSide(color: PdfColors.grey300),
            horizontalInside: const pw.BorderSide(color: PdfColors.grey300),
            verticalInside: const pw.BorderSide(color: PdfColors.grey300),
          ),

          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            fontSize: 10,
          ),
          cellStyle: const pw.TextStyle(fontSize: 11),

          headerDecoration: const pw.BoxDecoration(
            color: PdfColors.black,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(4),
              topRight: pw.Radius.circular(4),
            ),
          ),

          cellAlignment: pw.Alignment.center,
          headerAlignment: pw.Alignment.center,
        ),
      ),
    );
  }

  static pw.Widget _buildAmountInWords(Invoice invoice) {
    final amountInWords = NumberToWords.convert(
      'en',
      invoice.grandTotal.toInt(),
    );
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Amount in Words"),
            pw.Text(
              amountInWords,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildBankDetails() {
    const bankName = "The Car Surgeon";
    const accountHolderName = "The Car Surgeon";
    const accountNumber = "1234567890";
    const ifscCode = "SBIN0001234";

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Bank Details",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 8),

            pw.Table(
              columnWidths: {
                0: const pw.FixedColumnWidth(110), // Label
                1: const pw.FixedColumnWidth(10), // Colon
                2: const pw.FlexColumnWidth(), // Value
              },
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                _buildBankRow("Bank Name", bankName),
                _buildBankRow("Account Holder", accountHolderName),
                _buildBankRow("Account Number", accountNumber),
                _buildBankRow("IFSC Code", ifscCode),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.TableRow _buildBankRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),

        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(
            ":",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),

        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(value),
        ),
      ],
    );
  }

  static pw.Widget _buildSignature() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Center(
        child: pw.Padding(
          padding: pw.EdgeInsets.all(10),
          child: pw.Column(
            children: [
              pw.Text(
                "Signature",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // FOOTER
  // =====================================================
  static pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Text(
        "Thank you for choosing The Car Surgeon",
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }
}
