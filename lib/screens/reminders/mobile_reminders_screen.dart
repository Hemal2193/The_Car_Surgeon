import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/controllers/customer_controller.dart';
import 'package:tcs/controllers/invoice_controller.dart';
import 'package:tcs/controllers/reminder_controller.dart';
import 'package:tcs/controllers/vehicle_controller.dart';
import 'package:tcs/models/reminder_model.dart';
import 'package:tcs/screens/invoices/invoice_preview_screen.dart';
import 'package:tcs/services/whatsapp_share.dart';
import 'package:tcs/widgets/app_popup_menu.dart';
import 'package:tcs/widgets/erp_mobile_tile.dart';

class MobileRemindersScreen extends StatefulWidget {
  const MobileRemindersScreen({super.key});

  @override
  State<MobileRemindersScreen> createState() => _MobileRemindersScreenState();
}

class _MobileRemindersScreenState extends State<MobileRemindersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Reminder> _filteredReminders() {
    final reminderCtrl = Get.find<ReminderController>();
    if (_searchQuery.isEmpty) return reminderCtrl.reminders;

    final customerCtrl = Get.find<CustomerController>();
    final vehicleCtrl = Get.find<VehicleController>();

    return reminderCtrl.reminders.where((r) {
      final customer = customerCtrl.getCustomerById(r.customerId);
      final vehicle = vehicleCtrl.getVehicleById(r.vehicleId);
      final customerName = customer?.name.toLowerCase() ?? '';
      final vehicleMake = vehicle?.make.toLowerCase() ?? '';
      final vehicleModel = vehicle?.model.toLowerCase() ?? '';
      final regNo = vehicle?.registrationNumber.toLowerCase() ?? '';
      final title = r.title.toLowerCase();

      return title.contains(_searchQuery) ||
          customerName.contains(_searchQuery) ||
          vehicleMake.contains(_searchQuery) ||
          vehicleModel.contains(_searchQuery) ||
          regNo.contains(_searchQuery);
    }).toList();
  }

  (Color, String) _reminderUrgency(Reminder reminder) {
    if (reminder.completed) return (Colors.green, 'Done');

    final now = DateTime.now();
    final due = reminder.dueDate;

    if (due.isBefore(now)) return (Colors.red, 'Overdue');

    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    if (!due.isBefore(startOfWeek) && due.isBefore(endOfWeek)) {
      return (Colors.orange, 'This Week');
    }

    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);
    if (!due.isBefore(startOfMonth) && due.isBefore(startOfNextMonth)) {
      return (Colors.blue, 'This Month');
    }

    return (Colors.blue, 'Coming Month');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reminders',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value.trim().toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Search reminders...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GetBuilder<ReminderController>(
                  builder: (reminderCtrl) {
                    final reminders = _filteredReminders()
                      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

                    if (reminders.isEmpty) {
                      return const Center(child: Text('No reminders found'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 150),
                      itemCount: reminders.length,
                      itemBuilder: (context, index) {
                        return _buildReminderTile(reminders[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderTile(Reminder reminder) {
    final vehicleCtrl = Get.find<VehicleController>();
    final customerCtrl = Get.find<CustomerController>();
    final reminderCtrl = Get.find<ReminderController>();
    final invoiceCtrl = Get.find<InvoiceController>();

    final vehicle = vehicleCtrl.getVehicleById(reminder.vehicleId);
    final invoice = reminder.invoiceId == null
        ? null
        : invoiceCtrl.getInvoiceById(reminder.invoiceId!);
    final customer = customerCtrl.getCustomerById(reminder.customerId);

    final (Color color, String label) = _reminderUrgency(reminder);
    final isCompleted = reminder.completed;

    return ErpMobileTile(
      onTap: () {
        if (invoice != null) {
          Get.to(() => InvoicePreviewScreen(invoiceId: invoice.invoiceId));
        }
      },
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(Icons.notifications_outlined, color: color),
      ),
      title: reminder.title,
      subtitles: [
        if (customer != null) customer.name,
        if (vehicle != null &&
            (vehicle.make.isNotEmpty || vehicle.model.isNotEmpty))
          '${vehicle.make} ${vehicle.model}',
        if (vehicle != null && vehicle.registrationNumber.isNotEmpty)
          vehicle.registrationNumber,
        if (reminder.notes != null && reminder.notes!.trim().isNotEmpty)
          reminder.notes!,
      ],
      trailing: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                '${reminder.dueDate.day.toString().padLeft(2, '0')}-'
                '${reminder.dueDate.month.toString().padLeft(2, '0')}-'
                '${reminder.dueDate.year.toString().substring(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? Colors.grey : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AppPopupMenu(
            options: [
              if (!isCompleted)
                AppPopupMenuOption(
                  icon: Icons.check_sharp,
                  label: 'Mark as Done',
                  onTap: () {
                    reminderCtrl.toggleCompleted(reminder.reminderId);
                  },
                ),
              AppPopupMenuOption(
                icon: Icons.delete,
                label: 'Delete Reminder',
                onTap: () {
                  reminderCtrl.deleteReminder(reminder.reminderId);
                },
              ),
              AppPopupMenuOption(
                icon: Icons.share_outlined,
                label: 'Share on WhatsApp',
                onTap: () {
                  WhatsappShare.reminderShare(reminder.reminderId);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
