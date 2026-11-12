import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import 'home_screen.dart';

/// ============================================================================
/// USE CASE: UC-07 - Home Layout & App Navigation Shell
/// Đảm nhận: Thái San Yo (CE190435)
/// Mô tả: Khung điều hướng chính của ứng dụng sử dụng BottomNavigationBar 3 tab.
///        Duy trì trạng thái các màn hình với IndexedStack để không bị tải lại khi chuyển tab.
///        Tích hợp Badge số lượng giỏ hàng thời gian thực qua BlocBuilder<CartBloc>.
/// ============================================================================
class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  // Chỉ số tab hiện tại đang được chọn (0: Trang chủ, 1: Giỏ hàng, 2: Tài khoản)
  int _currentIndex = 0;

  /// Hàm chuyển đổi tab khi người dùng nhấn vào item trên BottomNavigationBar
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách 3 màn hình tương ứng với 3 tab
    // Tab 1: HomeScreen - Khám phá sản phẩm, banner, danh mục nhanh
    // Tab 2: CartScreen - Quản lý giỏ hàng; callback onExploreTap đưa người dùng về Tab 0 khi giỏ trống
    // Tab 3: ProfileScreen - Quản lý tài khoản (hỗ trợ cả khách vãng lai Lazy Login và user đã đăng nhập)
    final screens = [
      const HomeScreen(),
      CartScreen(onExploreTap: () => _onTabTapped(0)),
      const ProfileScreen(),
    ];

    return Scaffold(
      // IndexedStack giúp lưu giữ nguyên vẹn trạng thái scroll và state của từng tab khi chuyển đổi
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        // Lắng nghe CartBloc để tự động cập nhật số lượng món đồ trên badge icon Giỏ hàng
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            // Lấy tổng số lượng sản phẩm trong giỏ (nếu state là CartLoaded)
            final cartCount = cartState is CartLoaded
                ? cartState.totalQuantity
                : 0;

            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey.shade400,
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              elevation: 0,
              items: [
                // Tab 0: Trang chủ
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Trang chủ',
                ),
                // Tab 1: Giỏ hàng kèm Badge số lượng động
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: cartCount > 0,
                    label: Text('$cartCount'),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: cartCount > 0,
                    label: Text('$cartCount'),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.shopping_bag_rounded),
                  ),
                  label: 'Giỏ hàng',
                ),
                // Tab 2: Hồ sơ người dùng
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Tài khoản',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
