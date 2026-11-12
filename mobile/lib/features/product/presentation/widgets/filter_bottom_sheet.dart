import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../cubit/filter_cubit.dart';
import '../cubit/filter_state.dart';

// Modal chọn bộ lọc sản phẩm (UC-17)
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  // Hiển thị modal bộ lọc
  static Future<bool?> show(BuildContext context) {
    final filterCubit = context.read<FilterCubit>(); // Biến lấy instance FilterCubit hiện tại
    return showModalBottomSheet<bool>( // Trả về kết quả đóng modal (true nếu bấm Áp dụng)
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: filterCubit,
        child: const FilterBottomSheet(),
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // Danh sách các hãng thể thao
  static const List<String> _brandOptions = [
    'Nike',
    'Adidas',
    'Puma',
    'Under Armour',
    'Reebok',
    'Asics',
  ];

  // Danh sách danh mục / phân loại phụ
  static const List<String> _categoryOptions = [
    'Giày thể thao',
    'Áo thể thao',
    'Quần thể thao',
    'Phụ kiện thể thao',
    'Dụng cụ tập luyện',
    'Đồ bảo hộ & Hỗ trợ',
  ];

  late List<String> _tempBrands; // Biến tạm lưu danh sách hãng đang chọn trên modal
  late List<String> _tempCategories; // Biến tạm lưu danh mục đang chọn trên modal
  late double _tempMinPrice; // Biến tạm lưu giá tối thiểu
  late double _tempMaxPrice; // Biến tạm lưu giá tối đa

  @override
  void initState() {
    super.initState();
    final currentState = context.read<FilterCubit>().state; // Lấy bộ lọc hiện tại từ FilterCubit
    _tempBrands = List<String>.from(currentState.selectedBrands); // Lưu tạm hãng đang chọn
    _tempCategories = List<String>.from(currentState.selectedCategories); // Lưu tạm danh mục đang chọn
    _tempMinPrice = currentState.minPrice; // Gán giá min hiện tại
    _tempMaxPrice = currentState.maxPrice; // Gán giá max hiện tại
  }

  // Đặt lại các biến lọc tạm
  void _resetLocal() {
    setState(() {
      _tempBrands.clear(); // Xóa danh sách hãng tạm
      _tempCategories.clear(); // Xóa danh sách danh mục tạm
      _tempMinPrice = FilterState.minPriceLimit; // Reset giá min về 0
      _tempMaxPrice = FilterState.maxPriceLimit; // Reset giá max về 5tr
    });
  }

  // Áp dụng bộ lọc sang FilterCubit
  void _applyFilter() {
    context.read<FilterCubit>().updateFilter( // 3. Đẩy dữ liệu tạm sang FilterCubit.updateFilter()
          brands: _tempBrands,
          categories: _tempCategories,
          minPrice: _tempMinPrice,
          maxPrice: _tempMaxPrice,
        );
    Navigator.of(context).pop(true); // Đóng modal quay về ProductListScreen
  }

  @override
  Widget build(BuildContext context) {
    return Container( // Trả về khung giao diện chính của BottomSheet bộ lọc
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header: Tiêu đề và nút Đặt lại
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bộ lọc tìm kiếm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // 2.4 Bấm 'Đặt lại' -> reset các tiêu chí lọc
                  TextButton(
                    key: const Key('filter_reset_button'),
                    onPressed: _resetLocal,
                    child: const Text(
                      'Đặt lại',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Nội dung cuộn được: Khoảng giá, Thương hiệu, Danh mục
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // --- 1. KHOẢNG GIÁ ---
                  const Text(
                    'Khoảng giá',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CurrencyFormatter.formatVnd(_tempMinPrice),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text(
                        'đến',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatVnd(_tempMaxPrice),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  // 2.1 Kéo chọn khoảng giá
                  RangeSlider(
                    key: const Key('filter_price_slider'),
                    values: RangeValues(_tempMinPrice, _tempMaxPrice),
                    min: FilterState.minPriceLimit,
                    max: FilterState.maxPriceLimit,
                    divisions: 50,
                    activeColor: AppColors.primary,
                    inactiveColor: Colors.grey.shade200,
                    onChanged: (values) {
                      setState(() {
                        _tempMinPrice = values.start;
                        _tempMaxPrice = values.end;
                      });
                    },
                  ),
                  // Phím tắt chọn khoảng giá nhanh
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildPresetChip('Dưới 2tr', 0, 2000000),
                      _buildPresetChip('2tr - 3.5tr', 2000000, 3500000),
                      _buildPresetChip('Trên 3.5tr', 3500000, 5000000),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- 2. THƯƠNG HIỆU ---
                  const Text(
                    'Thương hiệu',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _brandOptions.map((brand) {
                      final isSelected = _tempBrands.contains(brand); // Biến bool kiểm tra hãng có đang được chọn không
                      // 2.2 Chọn thương hiệu (onSelected)
                      return FilterChip( // Trả về 1 thẻ chip cho phép chọn nhiều hãng
                        key: Key('filter_brand_$brand'),
                        label: Text(brand),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _tempBrands.add(brand);
                            } else {
                              _tempBrands.remove(brand);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // --- 3. DANH MỤC / PHÂN LOẠI PHỤ ---
                  const Text(
                    'Danh mục / Phân loại',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categoryOptions.map((cat) {
                      final isSelected = _tempCategories.contains(cat); // Biến bool kiểm tra danh mục có đang chọn không
                      // 2.3 Chọn danh mục phân loại (onSelected)
                      return FilterChip( // Trả về 1 thẻ chip chọn danh mục
                        key: Key('filter_category_$cat'),
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _tempCategories.add(cat);
                            } else {
                              _tempCategories.remove(cat);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),
            const SizedBox(height: 12),

            // Nút Áp dụng ở đáy
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  key: const Key('filter_apply_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  // 3. Bấm 'Áp dụng bộ lọc' -> gọi _applyFilter()
                  onPressed: _applyFilter,
                  child: const Text(
                    'Áp dụng bộ lọc',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dựng nút chọn nhanh khoảng giá
  Widget _buildPresetChip(String label, double min, double max) {
    final isSelected = _tempMinPrice == min && _tempMaxPrice == max; // Biến kiểm tra mốc giá này có đang được chọn không
    return ChoiceChip( // Trả về chip chọn 1 khoảng giá nhanh
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
        ),
      ),
      onSelected: (_) { // Khi bấm vào mốc giá nhanh -> gán min/max tương ứng
        setState(() {
          _tempMinPrice = min; // Gán giá min theo preset
          _tempMaxPrice = max; // Gán giá max theo preset
        });
      },
    );
  }
}
