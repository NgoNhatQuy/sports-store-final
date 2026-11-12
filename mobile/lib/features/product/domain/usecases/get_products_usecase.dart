import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

// UseCase lấy danh sách & tìm kiếm sản phẩm (UC-09)
class GetProductsUseCase {
  final ProductRepository repository;

  GetProductsUseCase(this.repository);

  // Gọi repository truy vấn sản phẩm theo keyword, categoryId, page
  Future<List<ProductEntity>> call({
    int page = 1,
    int size = 10,
    String? categoryId,
    String? keyword,
  }) {
    return repository.getProducts( // Chuyển tiếp tham số xuống tầng Data (Repository)
      page: page,
      size: size,
      categoryId: categoryId,
      keyword: keyword,
    );
  }
}
