import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/product_entity.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  // Tạo route mở màn hình tìm kiếm kèm SearchCubit
  static Route route() {
    return MaterialPageRoute( // Trả về đường dẫn điều hướng sang SearchScreen
      builder: (_) => BlocProvider(
        create: (_) => getIt<SearchCubit>(), // Khởi tạo SearchCubit từ GetIt
        child: const SearchScreen(),
      ),
    );
  }

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController(); // Biến controller quản lý chữ trong ô tìm kiếm

  @override
  void dispose() {
    _searchController.dispose(); // Giải phóng bộ nhớ controller khi thoát màn hình
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Trả về khung giao diện chính của màn hình tìm kiếm
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // 1. Ô nhập từ khóa
        title: TextField(
          controller: _searchController, // Controller quản lý chữ đang nhập
          autofocus: true, // Tự động bật bàn phím khi mở màn hình
          decoration: InputDecoration(
            hintText: 'Tìm kiếm giày, quần áo, thương hiệu...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: InputBorder.none,
          ),
          // 2. Gõ từ khóa -> gọi cubit.search(keyword)
          onChanged: (keyword) {
            context.read<SearchCubit>().search(keyword); // Gọi hàm tìm kiếm real-time mỗi khi gõ
            setState(() {}); // Cập nhật UI để hiện/ẩn nút X xóa nhanh
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty) // Chỉ hiện nút X khi ô tìm kiếm có chữ
            // 3. Bấm (X) -> gọi cubit.clear()
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
              onPressed: () {
                _searchController.clear(); // Xóa trắng chữ trong ô nhập
                context.read<SearchCubit>().clear(); // Đưa Cubit về trạng thái SearchInitial
                setState(() {}); // Ẩn nút X đi
              },
            ),
        ],
      ),
      // 4. Lắng nghe State vẽ UI (Loading/Empty/Loaded)
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) { // Đang tìm kiếm -> hiện vòng xoay chờ
            return const Center(child: CircularProgressIndicator()); // Trả về vòng xoay loading
          }

          if (state is SearchEmpty) { // Không thấy sản phẩm -> báo không tìm thấy
            return Center( // Trả về màn hình thông báo không có kết quả
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Không tìm thấy sản phẩm phù hợp với "${state.query}"',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          if (state is SearchError) { // Có lỗi tìm kiếm -> hiện thông báo lỗi màu đỏ
            return Center( // Trả về thông báo lỗi giữa màn hình
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (state is SearchLoaded) { // Tìm thấy sản phẩm -> vẽ danh sách kết quả
            return ListView.separated( // Trả về danh sách cuộn hiển thị các sản phẩm tìm được
              padding: const EdgeInsets.all(16),
              itemCount: state.products.length, // Số lượng sản phẩm tìm được
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = state.products[index]; // Lấy từng sản phẩm theo vị trí
                return _buildProductItem(context, product); // Trả về thẻ 1 sản phẩm
              },
            );
          }

          // Trạng thái ban đầu: Chưa nhập từ khóa
          return Center( // Trả về màn hình hướng dẫn nhập từ khóa ban đầu
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nhập từ khóa để tìm kiếm sản phẩm thể thao',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Render 1 sản phẩm
  Widget _buildProductItem(BuildContext context, ProductEntity product) {
    return InkWell(
      // 5. Chạm sản phẩm -> mở ProductDetailScreen
      onTap: () {
        Navigator.of(context).push(ProductDetailScreen.route(product)); // Chuyển sang màn hình chi tiết sản phẩm (UC-05)
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.formatVnd(product.price),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
