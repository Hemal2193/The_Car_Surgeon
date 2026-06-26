import 'dart:ffi';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:tcs/controllers/customer_controller.dart';
import 'package:tcs/controllers/invoice_controller.dart';
import 'package:tcs/controllers/reminder_controller.dart';
import 'package:tcs/controllers/vehicle_controller.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WhatsappShare {
  static Future<void> reminderShare(String reminderId) async {
    final reminder = Get.find<ReminderController>().getReminderById(reminderId);

    if (reminder == null) return;

    final vehicle = Get.find<VehicleController>().getVehicleById(
      reminder.vehicleId,
    );

    if (vehicle == null) return;

    final customer = Get.find<CustomerController>().getCustomerById(
      vehicle.customerId,
    );

    if (customer == null) return;

    final mobileNo = customer.contact1;

    if (mobileNo.trim().isEmpty) {
      return;
    }

    // Remove spaces, +91, dashes etc.
    String phone = mobileNo.replaceAll(RegExp(r'[^0-9]'), '');

    if (phone.startsWith('91') && phone.length > 10) {
      phone = phone.substring(phone.length - 10);
    }

    final msg =
        "Dear ${customer.name},\n\n"
        "The vehicle ${vehicle.make} ${vehicle.model} has an upcoming reminder for ${reminder.title}.\n\n"
        "Kindly visit The Car Surgeon.\n"
        "Thanks,\n"
        "The Car Surgeon";

    final encodedMsg = Uri.encodeComponent(msg);

    // ---------------- MOBILE ----------------
    if (Platform.isAndroid || Platform.isIOS) {
      await launchUrl(
        Uri.parse('https://wa.me/91$phone?text=$encodedMsg'),
        mode: LaunchMode.externalApplication,
      );
      return;
    }

    // ---------------- WINDOWS ----------------
    if (Platform.isWindows) {
      final whatsappUri = 'whatsapp://send?phone=91$phone&text=$encodedMsg';

      final operation = 'open'.toNativeUtf16();
      final file = whatsappUri.toNativeUtf16();

      try {
        final result = ShellExecute(
          0,
          operation,
          file,
          nullptr,
          nullptr,
          SW_SHOWNORMAL,
        );

        calloc.free(operation);
        calloc.free(file);

        // WhatsApp Desktop not installed
        if (result <= 32) {
          await launchUrl(
            Uri.parse('https://wa.me/91$phone?text=$encodedMsg'),
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (_) {
        calloc.free(operation);
        calloc.free(file);

        await launchUrl(
          Uri.parse('https://wa.me/91$phone?text=$encodedMsg'),
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }

  static Future<void> invoicePaymentReminder(String invoiceId) async {
    final invoice = Get.find<InvoiceController>().getInvoiceById(invoiceId);

    if (invoice == null) return;

    final customer = Get.find<CustomerController>().getCustomerById(
      invoice.customerId,
    );

    if (customer == null) return;

    final vehicle = Get.find<VehicleController>().getVehicleById(
      invoice.vehicleId,
    );

    if (vehicle == null) return;

    final mobileNo = customer.contact1;

    if (mobileNo.trim().isEmpty) {
      return;
    }

    // Remove spaces, +91, dashes etc.
    String phone = mobileNo.replaceAll(RegExp(r'[^0-9]'), '');

    if (phone.startsWith('91') && phone.length > 10) {
      phone = phone.substring(phone.length - 10);
    }

    final msg =
        "Dear ${customer.name},\n\n"
        "This is a gentle reminder that payment for Invoice ${invoice.invoiceId} "
        "is still pending.\n\n"
        "Vehicle: ${vehicle.make} ${vehicle.model} (${vehicle.registrationNumber})\n"
        "Outstanding Amount: ₹${invoice.balanceAmount.toStringAsFixed(2)}\n\n"
        "Kindly visit The Car Surgeon or contact us to complete the payment.\n\n"
        "Thank you,\n"
        "The Car Surgeon";

    final encodedMsg = Uri.encodeComponent(msg);

    // ---------------- MOBILE ----------------
    if (Platform.isAndroid || Platform.isIOS) {
      await launchUrl(
        Uri.parse('https://wa.me/91$phone?text=$encodedMsg'),
        mode: LaunchMode.externalApplication,
      );
      return;
    }

    // ---------------- WINDOWS ----------------
    if (Platform.isWindows) {
      final whatsappUri = 'whatsapp://send?phone=91$phone&text=$encodedMsg';

      final operation = 'open'.toNativeUtf16();
      final file = whatsappUri.toNativeUtf16();

      try {
        final result = ShellExecute(
          0,
          operation,
          file,
          nullptr,
          nullptr,
          SW_SHOWNORMAL,
        );

        calloc.free(operation);
        calloc.free(file);

        // WhatsApp Desktop not installed
        if (result <= 32) {
          await launchUrl(
            Uri.parse('https://wa.me/91$phone?text=$encodedMsg'),
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (_) {
        calloc.free(operation);
        calloc.free(file);

        await launchUrl(
          Uri.parse('https://wa.me/91$phone?text=$encodedMsg'),
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }
}
