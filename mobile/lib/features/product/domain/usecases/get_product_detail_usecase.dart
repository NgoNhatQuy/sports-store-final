import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

// UseCase lấy chi tiết sản phẩm (UC-05)
class GetProductDetailUseCase {
  final ProductRepository repository;

  GetProductDetailUseCase(this.repository);

  // Gọi repository lấy sản phẩm theo id
  Future<ProductEntity> call(String id) {
    return repository.getProductById(id); // Chuyển tiếp xuống tầng Data (Repository)
  }
}
