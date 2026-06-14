import 'package:get/get.dart';
import 'package:tcs/utils/app_pages.dart';

class AppNavigationController extends GetxController {
  final Rx<AppPage> currentPage = AppPage.dashboard.obs;

  void selectPage(AppPage page) {
    currentPage.value = page;
  }
}
