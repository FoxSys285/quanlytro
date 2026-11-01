import 'package:flutter/material.dart';

/// Phân trang sau khi lọc; chỉ dựng các thẻ thuộc trang đang xem.
class ListPagination extends StatelessWidget {
  const ListPagination({
    super.key,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.onChanged,
  });

  final int total;
  final int page;
  final int pageSize;
  final ValueChanged<int> onChanged;

  static int lastPage(int total, int pageSize) =>
      total == 0 ? 0 : (total - 1) ~/ pageSize;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    final last = lastPage(total, pageSize);
    final current = page.clamp(0, last);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            '${current * pageSize + 1}–${((current + 1) * pageSize).clamp(0, total)} / $total kết quả',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (last > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(
                  tooltip: 'Trang trước',
                  onPressed: current == 0 ? null : () => onChanged(current - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Trang ${current + 1} / ${last + 1}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Trang tiếp theo',
                  onPressed: current == last
                      ? null
                      : () => onChanged(current + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
