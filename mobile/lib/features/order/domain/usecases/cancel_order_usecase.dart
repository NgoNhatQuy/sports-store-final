import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

// UseCase hủy đơn hàng (UC-20)
class CancelOrderUseCase {
  final OrderRepository repository;

  CancelOrderUseCase(this.repository);

  // Gọi repository hủy đơn theo orderId và lý do
  Future<OrderEntity> call(String orderId, {String? reason}) {
    return repository.cancelOrder(orderId, reason: reason); // Chuyển tiếp xuống tầng Data (Repository)
  }
}
