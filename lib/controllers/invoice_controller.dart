import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../database/hive_boxes.dart';
import '../models/invoice_model.dart';

class InvoiceController extends GetxController {
  final Box<Invoice> invoiceBox = Hive.box<Invoice>(HiveBoxes.invoices);

  List<Invoice> get invoices => invoiceBox.values.toList();

  Future<void> addInvoice(Invoice invoice) async {
    await invoiceBox.put(invoice.invoiceId, invoice);
    update();
  }

  Future<void> deleteInvoice(String id) async {
    if (invoiceBox.containsKey(id)) {
      await invoiceBox.delete(id);
    } else {
      final invoice = invoices.firstWhereOrNull((inv) => inv.invoiceId == id);
      final key = invoice?.key;

      if (key != null) {
        await invoiceBox.delete(key);
      }
    }

    update();
  }
}
