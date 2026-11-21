import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/controllers/customer_controller.dart';
import 'package:tcs/controllers/reminder_controller.dart';
import 'package:tcs/controllers/vehicle_controller.dart';
import 'package:tcs/models/reminder_model.dart';
import 'package:tcs/services/whatsapp_share.dart';
import 'package:tcs/utils/responsive.dart';
import 'package:tcs/widgets/app_popup_menu.dart';

class DesktopRemindersScreen extends StatefulWidget {
  const DesktopRemindersScreen({super.key});

  @override
  State<DesktopRemindersScreen> createState() => _DesktopRemindersScreenState();
}

class _DesktopRemindersScreenState extends State<DesktopRemindersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedIds = {};

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
    if (Responsive.isMobile(context)) {
      return Center(
        child: Text(
          'Reminders',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Reminders',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_selectedIds.isNotEmpty)
                Text(
                  '${_selectedIds.length} selected',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value.trim().toLowerCase());
            },
            decoration: InputDecoration(
              hintText: 'Search reminders...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GetBuilder<ReminderController>(
              builder: (reminderCtrl) {
                final reminders = _filteredReminders()
                  ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

                if (reminders.isEmpty) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('No reminders found')),
                  );
                }

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: DataTable(
                      showCheckboxColumn: false,
                      checkboxHorizontalMargin: 12,
                      headingRowHeight: 40,
                      dataRowMinHeight: 44,
                      dataRowMaxHeight: 56,
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Reminder',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Customer',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Vehicle',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Reg No',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Due Date',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Actions',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      rows: reminders.map((r) {
                        final vehicle = Get.find<VehicleController>()
                            .getVehicleById(r.vehicleId);
                        final customer = Get.find<CustomerController>()
                            .getCustomerById(r.customerId);
                        // final invoiceCtrl = Get.find<InvoiceController>();
                        // final invoice = r.invoiceId == null
                        //     ? null
                        //     : invoiceCtrl.getInvoiceById(r.invoiceId!);
                        final (Color dotColor, String label) = _reminderUrgency(
                          r,
                        );
                        final bool isCompleted = r.completed;

                        return DataRow(
                          onSelectChanged: (selected) {
                            if (selected == true) {
                              setState(() {
                                if (_selectedIds.contains(r.reminderId)) {
                                  _selectedIds.remove(r.reminderId);
                                } else {
                                  _selectedIds.add(r.reminderId);
                                }
                              });
                            }
                          },
                          selected: _selectedIds.contains(r.reminderId),
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  if (isCompleted)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    )
                                  else
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: dotColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    r.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                customer?.name ?? 'Unknown',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            DataCell(
                              Text(
                                vehicle != null
                                    ? '${vehicle.make} ${vehicle.model}'
                                    : 'Unknown',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            DataCell(
                              Text(
                                vehicle?.registrationNumber ?? 'N/A',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${r.dueDate.day.toString().padLeft(2, '0')}-'
                                    '${r.dueDate.month.toString().padLeft(2, '0')}-'
                                    '${r.dueDate.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: isCompleted
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: dotColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: dotColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              AppPopupMenu(
                                options: [
                                  if (!isCompleted)
                                    AppPopupMenuOption(
                                      icon: Icons.check_sharp,
                                      label: 'Mark as Done',
                                      onTap: () {
                                        reminderCtrl.toggleCompleted(
                                          r.reminderId,
                                        );
                                      },
                                    ),
                                  AppPopupMenuOption(
                                    icon: Icons.delete_outline,
                                    label: 'Delete',
                                    onTap: () {
                                      reminderCtrl.deleteReminder(r.reminderId);
                                    },
                                  ),
                                  AppPopupMenuOption(
                                    icon: Icons.share_outlined,
                                    label: 'Share on WhatsApp',
                                    onTap: () {
                                      WhatsappShare.reminderShare(r.reminderId);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
