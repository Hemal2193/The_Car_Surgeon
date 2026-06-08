// ignore_for_file: deprecated_member_use

import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:tcs/controllers/customer_controller.dart';
import 'package:tcs/controllers/vehicle_controller.dart';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import '../models/invoice_model.dart';

class InvoicePdfService {
  // =====================================================
  // CREATE PDF DOCUMENT
  // =====================================================
  static pw.Document _buildPdfDocument(Invoice invoice) {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(invoice),

              pw.SizedBox(height: 20),

              _buildCustomerBlock(invoice),

              pw.SizedBox(height: 20),

              _buildItemsTable(invoice),

              pw.SizedBox(height: 20),

              _buildTaxSummaryTable(invoice),

              pw.Spacer(),

              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // =====================================================
  // PDF BYTES (FOR PREVIEW)
  // =====================================================
  static Future<Uint8List> generatePdfBytes(Invoice invoice) async {
    final pdf = _buildPdfDocument(invoice);

    return pdf.save();
  }

  // =====================================================
  // SHARE PDF
  // =====================================================
  static Future<void> shareInvoicePdf(Invoice invoice) async {
    final bytes = await generatePdfBytes(invoice);

    await Printing.sharePdf(bytes: bytes, filename: '${invoice.invoiceId}.pdf');
  }

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
  // HEADER
  // =====================================================
  static pw.Widget _buildHeader(Invoice invoice) {
    final vehicleController = Get.find<VehicleController>();

    final vehicle = vehicleController.getVehicleById(invoice.vehicleId);

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
              pw.Row(
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
                          pw.MemoryImage(
                            File('assets/logo.jpeg').readAsBytesSync(),
                          ),
                          width: 80,
                          height: 80,
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
                                  ), // Style before newline
                                ),
                                pw.TextSpan(
                                  text: "24ABWPW0365P1ZO",
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.normal,
                                    fontSize: 12,
                                    color: PdfColors.grey900,
                                  ), // Style after newline
                                ),
                              ],
                            ),
                          ),

                          pw.SizedBox(width: 20),

                          // Contact Block
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: "Contact: \n",
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                  ), // Style before newline
                                ),
                                pw.TextSpan(
                                  text: "7069779966",
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.normal,
                                    fontSize: 12,
                                    color: PdfColors.grey900,
                                  ), // Style after newline
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: "Pan No: \n",
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9,
                              ), // Style before newline
                            ),
                            pw.TextSpan(
                              text: "ABWPW0365P",
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.normal,
                                fontSize: 11,
                                color: PdfColors.grey900,
                              ), // Style after newline
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: "Email: \n",
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9,
                              ), // Style before newline
                            ),
                            pw.TextSpan(
                              text: "thecarsurgeonbaroda@gmail.com",
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.normal,
                                fontSize: 11,
                                color: PdfColors.grey900,
                              ), // Style after newline
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  //invoice card
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: [
                        pw.Column(
                          children: [
                            pw.Text(
                              "Invoice Id",
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              invoice.invoiceId,
                              style: pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        pw.SizedBox(width: 15),
                        pw.Column(
                          children: [
                            pw.Text(
                              "Invoice Date",
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              "${invoice.dateTime.day.toString().padLeft(2, '0')}-"
                              "${invoice.dateTime.month.toString().padLeft(2, '0')}-"
                              "${(invoice.dateTime.year % 100).toString().padLeft(2, '0')}",
                              style: pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        pw.SizedBox(width: 15),

                        pw.Column(
                          children: [
                            pw.Text(
                              "Due Date",
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              "${invoice.dateTime.day.toString().padLeft(2, '0')}-"
                              "${invoice.dateTime.month.toString().padLeft(2, '0')}-"
                              "${(invoice.dateTime.year % 100).toString().padLeft(2, '0')}",
                              style: pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  //vehicle card
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),

                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: [
                        pw.Column(
                          children: [
                            pw.Text(
                              "Vehicle No",
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              vehicle!.registrationNumber,
                              style: pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        pw.SizedBox(width: 15),
                        pw.Column(
                          children: [
                            pw.Text(
                              "Odometer",
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              "12435 KM",
                              style: pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        pw.SizedBox(width: 15),

                        pw.Column(
                          children: [
                            pw.Text(
                              "Model",
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              "${vehicle.make} ${vehicle.model}",
                              style: pw.TextStyle(fontSize: 10),
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
          child: pw.Text(label, style: pw.TextStyle(fontSize: 12)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(":"),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(
            value?.toString() ?? "N/A",
            style: pw.TextStyle(fontSize: 12),
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

  // =====================================================
  // TOTAL SECTION
  // =====================================================
  // static pw.Widget _buildTotalSection(Invoice invoice) {
  //   final subtotal = invoice.items.fold<double>(
  //     0,
  //     (sum, e) => sum + (e.qty * e.rate),
  //   );

  //   final tax = invoice.items.fold<double>(0, (sum, e) => sum + e.taxAmount);

  //   final grand = subtotal + tax;

  //   return pw.Container(
  //     alignment: pw.Alignment.centerRight,
  //     child: pw.Container(
  //       width: 200,
  //       padding: const pw.EdgeInsets.all(10),
  //       decoration: pw.BoxDecoration(
  //         border: pw.Border.all(),
  //         borderRadius: pw.BorderRadius.circular(8),
  //       ),
  //       child: pw.Column(
  //         crossAxisAlignment: pw.CrossAxisAlignment.start,
  //         children: [
  //           _row("Subtotal", subtotal),
  //           _row("Tax", tax),
  //           pw.Divider(),
  //           pw.Row(
  //             mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  //             children: [
  //               pw.Text(
  //                 "Grand Total: Rs.",
  //                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
  //               ),
  //               pw.Text(
  //                 grand.toStringAsFixed(2),
  //                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // static pw.Widget _row(String label, double value) {
  //   return pw.Row(
  //     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  //     children: [pw.Text(label), pw.Text("Rs. ${value.toStringAsFixed(2)}")],
  //   );
  // }

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
