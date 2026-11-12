import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../domain/repositories/order_repository.dart';
import '../cubit/cancel_order_cubit.dart';
import '../cubit/cancel_order_state.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final String date;
  final String status;
  final Color statusColor;
  final String productName;
  final String productInfo;
  final String total;
  final IconData icon;
  final ValueChanged<String>? onStatusChanged;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.productName,
    required this.productInfo,
    required this.total,
    required this.icon,
    this.onStatusChanged,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final CancelOrderCubit _cancelOrderCubit;
  late String _currentStatus;
  late Color _currentStatusColor;
  String _selectedReason = 'Đổi ý không muốn mua nữa';

  final List<String> _cancelReasons = [
    'Đổi ý không muốn mua nữa',
    'Đặt nhầm kích cỡ (Size) hoặc màu sắc',
    'Muốn thay đổi địa chỉ nhận hàng',
    'Tìm thấy giá tốt hơn ở nơi khác',
    'Lý do khác',
  ];

  @override
  void initState() {
    super.initState();
    _cancelOrderCubit = getIt<CancelOrderCubit>();
    _currentStatus = widget.status;
    _currentStatusColor = widget.statusColor;
    _syncStatus();
  }

  @override
  void dispose() {
    _cancelOrderCubit.close();
    super.dispose();
  }

  Future<void> _syncStatus() async {
    try {
      final orders = await getIt<OrderRepository>().getOrders();
      final match = orders.where((o) => o.id == widget.orderId).firstOrNull;
      if (match != null && mounted) {
        setState(() {
          _currentStatus = match.status;
          final lower = match.status.toLowerCase();
          if (lower.contains('hủy') || lower.contains('cancel')) {
            _currentStatusColor = Colors.red;
          } else if (lower.contains('chờ') || lower.contains('pending')) {
            _currentStatusColor = AppColors.primary;
          } else if (lower.contains('đang')) {
            _currentStatusColor = Colors.blue;
          } else {
            _currentStatusColor = Colors.green;
          }
        });
      }
    } catch (_) {}
  }

  // Chỉ cho phép hủy khi đơn ở trạng thái 'Chờ xác nhận'
  // Kiểm tra trạng thái được phép hủy đơn
  bool get _canCancel {
    final lower = _currentStatus.toLowerCase(); // Đưa trạng thái về chữ thường
    return lower.contains('chờ') || lower.contains('pending'); // Chỉ cho hủy khi đơn đang chờ xác nhận
  }

  /// Hộp thoại xác nhận hủy đơn (UC-20)
  Future<void> _showCancelDialog() async {
    // 2. Hiện dialog chọn lý do hủy
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text(
                'Xác nhận hủy đơn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có chắc chắn muốn hủy đơn hàng #${widget.orderId} không?',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chọn lý do hủy:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedReason,
                    items: _cancelReasons.map((reason) {
                      return DropdownMenuItem<String>(
                        value: reason,
                        child: Text(
                          reason,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) { // 2.1 Chọn lý do hủy đơn từ danh sách
                      if (val != null) {
                        setDialogState(() => _selectedReason = val); // Cập nhật lý do tạm trong dialog
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false), // Bấm Quay lại -> đóng dialog, không hủy
              child: const Text('Quay lại', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true), // 2.2 Bấm Xác nhận -> trả về true đóng dialog
              child: const Text('Xác nhận hủy'),
            ),
          ],
        ),
      ),
    );

    // 3. Xác nhận hủy -> gọi cubit.cancelOrder()
    if (confirmed == true && mounted) {
      if (!_canCancel) return; // Chặn nếu đơn không còn ở trạng thái chờ
      _cancelOrderCubit.cancelOrder( // Gọi Cubit thực thi hủy đơn
        widget.orderId,
        reason: _selectedReason,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Chi tiết đơn hàng',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<CancelOrderCubit, CancelOrderState>(
        bloc: _cancelOrderCubit,
        listener: (context, state) { // 4. Lắng nghe kết quả từ CancelOrderCubit
          if (state is CancelOrderSuccess) { // 4a. Hủy thành công -> đổi UI sang 'Đã hủy'
            setState(() {
              _currentStatus = 'Đã hủy'; // Cập nhật chữ trạng thái
              _currentStatusColor = Colors.red; // Đổi màu trạng thái sang đỏ
            });
            widget.onStatusChanged?.call('Đã hủy'); // Báo cho màn hình danh sách cập nhật theo

            ScaffoldMessenger.of(context).showSnackBar( // Hiện thông báo xanh thành công
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is CancelOrderError) { // 4b. Hủy thất bại -> hiện thông báo lỗi đỏ
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is CancelOrderLoading; // Kiểm tra trạng thái đang xử lý hủy

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '#${widget.orderId}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Trạng thái',
                value: _currentStatus,
                valueColor: _currentStatusColor,
              ),
              _InfoRow(label: 'Ngày đặt', value: widget.date),
              const SizedBox(height: 12),
              const Text(
                'Sản phẩm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, color: AppColors.primary, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.productName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.productInfo,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _InfoRow(
                label: 'Tổng thanh toán',
                value: widget.total,
                valueColor: AppColors.primary,
              ),
              const SizedBox(height: 32),

              // Nút hủy đơn hàng
              if (_canCancel)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    // 1. Bấm HỦY ĐƠN -> gọi _showCancelDialog()
                    onPressed: isLoading ? null : _showCancelDialog,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          )
                        : const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: Text(
                      isLoading ? 'Đang xử lý hủy...' : 'HỦY ĐƠN HÀNG',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                )
              else if (_currentStatus.toLowerCase().contains('hủy') ||
                  _currentStatus.toLowerCase().contains('cancel'))
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Đơn hàng này đã được hủy thành công.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _currentStatus.toLowerCase().contains('đang')
                            ? 'Đơn hàng đang giao, không thể hủy.'
                        : 'Đơn hàng đã hoàn thành.',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
