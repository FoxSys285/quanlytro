import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../layouts/role_layout.dart';
import '../../landlord/landlord_ui.dart';
import 'help_content.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key, required this.role});

  final AppRole role;

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final _searchController = TextEditingController();
  String _category = 'Tất cả';

  bool get _isTenant => widget.role == AppRole.tenant;
  Color get _color => _isTenant ? const Color(0xFF16836F) : landlordBlue;

  @override
  void didUpdateWidget(covariant HelpPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      _searchController.clear();
      _category = 'Tất cả';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showGuide(HelpArticle article) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(article.category, style: TextStyle(color: _color)),
              const SizedBox(height: 8),
              Text(
                article.question,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              Text(article.answer, style: const TextStyle(height: 1.8)),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đã hiểu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyIssueTemplate() async {
    await Clipboard.setData(
      ClipboardData(
        text:
            'Vai trò: ${widget.role.label}\n'
            'Nhà trọ / phòng: \n'
            'Màn hình gặp vấn đề: \n'
            'Thao tác đã thực hiện: \n'
            'Kết quả mong muốn: \n'
            'Vấn đề thực tế và thời điểm xảy ra: ',
      ),
    );
    if (!mounted) return;
    showLandlordMessage(context, 'Đã sao chép mẫu mô tả vấn đề.');
  }

  @override
  Widget build(BuildContext context) {
    final articles = helpArticlesFor(widget.role);
    final categories = ['Tất cả', ...articles.map((a) => a.category).toSet()];
    final query = normalizeHelpQuery(_searchController.text);
    final filtered = articles.where((article) {
      final text = normalizeHelpQuery(
        '${article.category} ${article.question} ${article.answer}',
      );
      return (_category == 'Tất cả' || article.category == _category) &&
          text.contains(query);
    }).toList();

    return LandlordPageFrame(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _color,
                _isTenant ? const Color(0xFF105F53) : const Color(0xFF234891),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'DÀNH CHO ${widget.role.label.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Bạn cần trợ giúp gì?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isTenant
                    ? 'Từ tìm phòng đến cuộc sống ở trọ, tìm hướng dẫn bạn cần tại đây.'
                    : 'Hướng dẫn quản lý nhà trọ, thu chi và đồng hành cùng người thuê.',
                style: const TextStyle(
                  color: Color(0xFFE4EEF7),
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Tìm hướng dẫn, câu hỏi…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa tìm kiếm',
                          onPressed: () => setState(_searchController.clear),
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Hướng dẫn nhanh'),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 600
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              children: [
                for (final index in [0, 2])
                  SizedBox(
                    width: width,
                    child: LandlordCard(
                      onTap: () => _showGuide(articles[index]),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: _color.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              index == 0
                                  ? Icons.auto_stories_outlined
                                  : Icons.receipt_long_outlined,
                              color: _color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  index == 0
                                      ? (_isTenant
                                            ? 'Tìm chỗ ở phù hợp'
                                            : 'Thiết lập nhà trọ')
                                      : (_isTenant
                                            ? 'Thanh toán tiền phòng'
                                            : 'Lập hóa đơn'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Xem hướng dẫn từng bước',
                                  style: TextStyle(
                                    color: landlordMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: landlordMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        const _SectionTitle('Câu hỏi thường gặp'),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final category in categories)
              ChoiceChip(
                label: Text(category),
                selected: _category == category,
                selectedColor: _color.withValues(alpha: 0.12),
                onSelected: (_) => setState(() => _category = category),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${filtered.length} câu hỏi',
          style: const TextStyle(color: landlordMuted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          LandlordCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, size: 36, color: _color),
                const SizedBox(height: 10),
                const Text(
                  'Chưa tìm thấy hướng dẫn phù hợp',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Thử từ khóa khác hoặc xem tất cả chủ đề.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: landlordMuted),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _category = 'Tất cả';
                    _searchController.clear();
                  }),
                  child: const Text('Xem tất cả câu hỏi'),
                ),
              ],
            ),
          )
        else
          for (final article in filtered)
            LandlordCard(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                key: ValueKey('${widget.role.name}-${article.question}'),
                iconColor: _color,
                shape: const Border(),
                collapsedShape: const Border(),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                subtitle: Text(
                  article.category,
                  style: TextStyle(fontSize: 11, color: _color),
                ),
                title: Text(
                  article.question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.answer,
                    style: const TextStyle(
                      color: landlordMuted,
                      height: 1.7,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 14),
        LandlordCard(
          backgroundColor: _color.withValues(alpha: 0.05),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Cần hỗ trợ thêm?'),
              Text(
                _isTenant
                    ? 'Với vấn đề về phòng, hóa đơn hoặc hợp đồng, hãy trao đổi với chủ trọ qua Tin nhắn. Với hư hỏng trong phòng, hãy gửi yêu cầu ở Báo sự cố.'
                    : 'Với vấn đề về hợp đồng hoặc thanh toán, hãy trao đổi với người thuê qua Tin nhắn. Kiểm tra Yêu cầu sửa chữa để theo dõi các sự cố của nhà trọ.',
                style: const TextStyle(
                  color: landlordMuted,
                  height: 1.6,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Khi mô tả lỗi ứng dụng, ghi rõ màn hình, thao tác và thời điểm gặp lỗi để người hỗ trợ dễ kiểm tra.',
                style: TextStyle(
                  color: landlordMuted,
                  height: 1.6,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _copyIssueTemplate,
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Sao chép mẫu mô tả'),
                style: OutlinedButton.styleFrom(foregroundColor: _color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(
        color: landlordInk,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
