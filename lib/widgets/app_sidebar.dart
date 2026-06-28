import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/screens/login/login_screen.dart';
import 'package:tcs/services/auth_service.dart';
import 'package:tcs/utils/app_pages.dart';

class AppSidebar extends StatelessWidget {
  final AppPage currentPage;
  final Function(AppPage) onPageSelected;

  const AppSidebar({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.black,
      child: Column(
        children: [
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/logo.jpeg',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'THE CAR SURGEON',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          _buildMenuItem(
            title: 'Dashboard',
            icon: Icons.dashboard_outlined,
            page: AppPage.dashboard,
          ),

          _buildMenuItem(
            title: 'Customers',
            icon: Icons.people_outline,
            page: AppPage.customers,
          ),

          _buildMenuItem(
            title: 'Vehicles',
            icon: Icons.directions_car_outlined,
            page: AppPage.vehicles,
          ),

          _buildMenuItem(
            title: 'Invoices',
            icon: Icons.receipt_long_outlined,
            page: AppPage.invoices,
          ),

          _buildMenuItem(
            title: 'Payments',
            icon: Icons.payments_outlined,
            page: AppPage.payments,
          ),

          _buildMenuItem(
            title: 'Items',
            icon: Icons.inventory_2_outlined,
            page: AppPage.items,
          ),

          const Spacer(),

          const Divider(color: Colors.white24, height: 1, thickness: 1),

          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: () async {
        await AuthService.logout();
        Get.offAll(() => const LoginScreen());
      },
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.logout, color: Colors.white70),
            SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required AppPage page,
  }) {
    bool isSelected = currentPage == page;

    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: () {
        onPageSelected(page);
      },
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.white),

            const SizedBox(width: 12),

            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
