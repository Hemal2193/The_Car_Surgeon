import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/controllers/app_navigation_controller.dart';
import 'package:tcs/screens/customers/add_customer_dialog.dart';
import 'package:tcs/screens/customers/customers_screen.dart';
import 'package:tcs/screens/dashboard/dashboard_screen.dart';
import 'package:tcs/screens/invoices/create_invoice_screen.dart';
import 'package:tcs/screens/invoices/invoices_screen.dart';
import 'package:tcs/screens/items/add_item_dialog.dart';
import 'package:tcs/screens/items/items_screen.dart';
import 'package:tcs/screens/vehicles/add_vehicle_dialog.dart';
import 'package:tcs/screens/vehicles/vehicles_screen.dart';
import 'package:tcs/utils/app_pages.dart';
import 'package:tcs/utils/responsive.dart';
import 'package:tcs/widgets/app_sidebar.dart';
import 'package:tcs/widgets/app_titlebar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  AppNavigationController get navigationController =>
      Get.find<AppNavigationController>();

  Widget getCurrentScreen(AppPage currentPage) {
    switch (currentPage) {
      case AppPage.dashboard:
        return const DashboardScreen();

      case AppPage.customers:
        return const CustomersScreen();

      case AppPage.vehicles:
        return const VehiclesScreen();

      case AppPage.invoices:
        return const InvoicesScreen();

      case AppPage.items:
        return const ItemsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentPage = navigationController.currentPage.value;

      if (Responsive.isDesktop(context)) {
        return Scaffold(
          body: Row(
            children: [
              AppSidebar(
                currentPage: currentPage,
                onPageSelected: navigationController.selectPage,
              ),
              Expanded(
                child: Column(
                  children: [
                    const AppTitleBar(),
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: getCurrentScreen(currentPage),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      //-------------------------------
      //------Mobile-------------------
      //-------------------------------
      return Scaffold(
        backgroundColor: Colors.white,

        floatingActionButton: _buildCurrentFab(context, currentPage),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        body: Stack(
          children: [
            // Main content
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: getCurrentScreen(currentPage),
              ),
            ),

            // Floating navbar
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    children: [
                      _navItem(
                        currentPage: currentPage,
                        page: AppPage.dashboard,
                        icon: Icons.dashboard_outlined,
                        selectedIcon: Icons.dashboard,
                        label: 'Dashboard',
                      ),
                      _navItem(
                        currentPage: currentPage,
                        page: AppPage.customers,
                        icon: Icons.people_outline,
                        selectedIcon: Icons.people,
                        label: 'Customers',
                      ),
                      _navItem(
                        currentPage: currentPage,
                        page: AppPage.vehicles,
                        icon: Icons.directions_car_outlined,
                        selectedIcon: Icons.directions_car,
                        label: 'Vehicles',
                      ),
                      _navItem(
                        currentPage: currentPage,
                        page: AppPage.invoices,
                        icon: Icons.receipt_long_outlined,
                        selectedIcon: Icons.receipt_long,
                        label: 'Invoices',
                      ),
                      _navItem(
                        currentPage: currentPage,
                        page: AppPage.items,
                        icon: Icons.inventory_2_outlined,
                        selectedIcon: Icons.inventory_2,
                        label: 'Items',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget? _buildCurrentFab(BuildContext context, AppPage currentPage) {
    switch (currentPage) {
      case AppPage.customers:
        return _customerFab(context);

      case AppPage.vehicles:
        return _vehicleFab(context);

      case AppPage.invoices:
        return _invoiceFab();

      case AppPage.items:
        return _itemFab(context);

      default:
        return null;
    }
  }

  Widget _customerFab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton.extended(
        label: const Text('Add Customer'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: true,
            backgroundColor: Colors.transparent,
            builder: (_) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.80,
                minChildSize: 0.80,
                maxChildSize: 0.92,
                shouldCloseOnMinExtent: true,
                builder: (context, scrollController) {
                  return AddCustomerDialog(scrollController: scrollController);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _vehicleFab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton.extended(
        label: const Text('Add Vehicle'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: true,
            backgroundColor: Colors.transparent,
            builder: (_) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.80,
                minChildSize: 0.80,
                maxChildSize: 0.92,
                shouldCloseOnMinExtent: true,
                builder: (context, scrollController) {
                  return AddVehicleDialog(scrollController: scrollController);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _invoiceFab() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton.extended(
        label: const Text('New Invoice'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () {
          Get.to(() => const CreateInvoiceScreen());
        },
      ),
    );
  }

  Widget _itemFab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton.extended(
        label: const Text('Add Item'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: true,
            backgroundColor: Colors.transparent,
            builder: (_) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.80,
                minChildSize: 0.80,
                maxChildSize: 0.92,
                shouldCloseOnMinExtent: true,
                builder: (context, scrollController) {
                  return AddItemDialog(scrollController: scrollController);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _navItem({
    required AppPage currentPage,
    required AppPage page,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = currentPage == page;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => navigationController.selectPage(page),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
