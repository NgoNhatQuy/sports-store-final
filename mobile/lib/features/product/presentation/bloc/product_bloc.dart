import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_products_usecase.dart';
import 'product_event.dart';
import 'product_state.dart';

/// ============================================================================
/// USE CASE: UC-04 - View Product List & Infinite Scroll
/// Đảm nhận: Thái San Yo (CE190435)
/// Mô tả: BLoC quản lý trạng thái tải danh sách sản phẩm, phân trang vô tận
///        (Infinite Scroll), lọc theo danh mục hoặc từ khóa tìm kiếm.
/// Kiến trúc: Feature-First Clean Architecture (Tầng Presentation - State Management)
/// ============================================================================
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  // Use case thuộc tầng Domain chịu trách nhiệm lấy danh sách sản phẩm
  final GetProductsUseCase getProductsUseCase;

  // Kích thước mỗi trang dữ liệu (Pagination size)
  static const int pageSize = 6;

  ProductBloc({required this.getProductsUseCase}) : super(const ProductInitial()) {
    // Đăng ký bộ xử lý cho sự kiện tải danh sách sản phẩm ban đầu hoặc làm mới
    on<FetchProductsEvent>(_onFetchProducts);

    // Đăng ký bộ xử lý cho sự kiện cuộn trang tải thêm sản phẩm (Infinite Scroll)
    on<FetchMoreProductsEvent>(_onFetchMoreProducts);
  }

  /// --------------------------------------------------------------------------
  /// Hàm: _onFetchProducts
  /// Mục đích: Xử lý sự kiện tải trang đầu tiên (Page 1) hoặc khi người dùng kéo
  ///           để làm mới (Pull-to-Refresh) / chuyển đổi bộ lọc danh mục.
  /// Luồng thực thi:
  ///   1. Phát ra state ProductLoading để giao diện hiển thị hiệu ứng Shimmer Skeleton.
  ///   2. Gọi UseCase với page = 1, pageSize = 6 kèm categoryId / keyword (nếu có).
  ///   3. Nếu thành công: Phát ProductLoaded với danh sách ban đầu, tính toán hasReachedMax.
  ///   4. Nếu thất bại: Phát ProductError thông báo lỗi thân thiện cho người dùng.
  /// --------------------------------------------------------------------------
  Future<void> _onFetchProducts(
    FetchProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    // 1. Phát trạng thái đang tải (Loading) để UI hiển thị Skeleton Shimmer
    emit(const ProductLoading());
    try {
      // 2. Gọi tầng Domain UseCase để lấy dữ liệu trang đầu tiên
      final products = await getProductsUseCase(
        page: 1,
        size: pageSize,
        categoryId: event.categoryId,
        keyword: event.keyword,
      );

      // 3. Phát trạng thái tải thành công (Loaded)
      // hasReachedMax = true nếu số lượng trả về ít hơn pageSize (đã hết dữ liệu ở server)
      emit(ProductLoaded(
        products: products,
        hasReachedMax: products.length < pageSize,
        currentPage: 1,
      ));
    } catch (e) {
      // 4. Bắt lỗi ngoại lệ và phát trạng thái lỗi thân thiện với người dùng
      emit(ProductError(
        message: 'Không thể tải danh sách sản phẩm. Vui lòng thử lại sau.',
      ));
    }
  }

  /// --------------------------------------------------------------------------
  /// Hàm: _onFetchMoreProducts
  /// Mục đích: Xử lý tính năng Infinite Scroll (phân trang khi cuộn tới cuối danh sách).
  /// Cơ chế bảo vệ (Guard Clauses):
  ///   - Chỉ thực hiện nếu state hiện tại là ProductLoaded.
  ///   - Bỏ qua nếu đã đạt trang cuối (hasReachedMax == true).
  ///   - Bỏ qua nếu đang trong quá trình tải thêm (isLoadingMore == true) để chống spam request.
  /// Luồng thực thi:
  ///   1. Bật cờ isLoadingMore = true trên state hiện tại (hiển thị indicator nhỏ dưới đáy).
  ///   2. Gọi getProductsUseCase với nextPage = currentPage + 1.
  ///   3. Nối danh sách mới vào danh sách cũ: [...currentState.products, ...moreProducts].
  ///   4. Cập nhật hasReachedMax nếu danh sách mới trả về rỗng hoặc < pageSize.
  /// --------------------------------------------------------------------------
  Future<void> _onFetchMoreProducts(
    FetchMoreProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    final currentState = state;

    // Kiểm tra điều kiện tiên quyết: BLoC phải đang ở trạng thái ProductLoaded
    if (currentState is! ProductLoaded) return;

    // Guard Clause: Tránh gọi trùng lặp nếu đã hết dữ liệu hoặc đang tải dở
    if (currentState.hasReachedMax || currentState.isLoadingMore) return;

    // Đánh dấu cờ đang tải thêm để UI hiển thị vòng xoay loading nhỏ ở chân trang
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      // Tính toán trang tiếp theo cần lấy
      final nextPage = currentState.currentPage + 1;
      final moreProducts = await getProductsUseCase(
        page: nextPage,
        size: pageSize,
      );

      if (moreProducts.isEmpty) {
        // Nếu server không trả thêm sản phẩm nào, đánh dấu đã đạt giới hạn tối đa
        emit(currentState.copyWith(
          hasReachedMax: true,
          isLoadingMore: false,
        ));
      } else {
        // Nối danh sách sản phẩm trang mới vào danh sách hiện tại và cập nhật số trang
        emit(ProductLoaded(
          products: [...currentState.products, ...moreProducts],
          hasReachedMax: moreProducts.length < pageSize,
          isLoadingMore: false,
          currentPage: nextPage,
        ));
      }
    } catch (e) {
      // Khi gặp lỗi mạng trong lúc cuộn thêm, tắt cờ loading để người dùng có thể cuộn thử lại
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }
}
