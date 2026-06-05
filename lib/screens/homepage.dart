import 'package:flutter/material.dart';
import 'package:tcs/screens/customers/customers_screen.dart';
import 'package:tcs/screens/dashboard/dashboard_screen.dart';
import 'package:tcs/screens/invoices/invoices_screen.dart';
import 'package:tcs/screens/items/items_screen.dart';
import 'package:tcs/screens/vehicles/vehicles_screen.dart';
import 'package:tcs/utils/app_pages.dart';
import 'package:tcs/widgets/app_sidebar.dart';
import 'package:tcs/widgets/app_titlebar.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AppPage currentPage = AppPage.dashboard;

  Widget getCurrentScreen() {
    switch (currentPage) {
      case AppPage.dashboard:
        return const DashboardScreen();

      case AppPage.customers:
        return const CustomersScreen();

      case AppPage.vehicles:
        return const VehiclesScreen();

      case AppPage.items:
        return const ItemsScreen();

      case AppPage.invoices:
        return const InvoicesScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            currentPage: currentPage,
            onPageSelected: (page) {
              setState(() {
                currentPage = page;
              });
            },
          ),

          Expanded(
            child: Column(
              children: [
                const AppTitleBar(),

                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: getCurrentScreen(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}