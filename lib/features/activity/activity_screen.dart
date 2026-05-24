import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import 'activity_service.dart';

/// Kullanıcının son 30 aktivitesi (ziyaretler + favoriler + yorumlar).
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<ActivityItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await ActivityService.getMyActivity();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk';
    if (diff.inHours < 24) return '${diff.inHours}sa';
    if (diff.inDays < 7) return '${diff.inDays}g';
    return DateFormat('d MMM', 'tr_TR').format(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(I18n.t('activity.title')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📭', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 12),
                        Text(
                          I18n.t('activity.title'),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final a = _items[i];
                      final isFirstOfDay = i == 0 ||
                          !_isSameDay(_items[i - 1].time, a.time);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isFirstOfDay)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                              child: Text(
                                _dateHeader(a.time),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          _ActivityTile(
                            item: a,
                            relTime: _relativeTime(a.time),
                            onTap: a.placeId == null
                                ? null
                                : () => context.push('/place/${a.placeId}'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateHeader(DateTime t) {
    final now = DateTime.now();
    if (_isSameDay(now, t)) return 'BUGÜN';
    if (_isSameDay(now.subtract(const Duration(days: 1)), t)) return 'DÜN';
    return DateFormat('d MMM yyyy', 'tr_TR').format(t).toUpperCase();
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityItem item;
  final String relTime;
  final VoidCallback? onTap;
  const _ActivityTile({
    required this.item,
    required this.relTime,
    this.onTap,
  });

  Color _bg() {
    switch (item.type) {
      case 'visit':
        return const Color(0xFFEFF6FF);
      case 'favorite':
        return const Color(0xFFFFF1F2);
      case 'review':
        return const Color(0xFFFEF9C3);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bg(),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              Text(item.placeEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.typeEmoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.placeName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.typeLabel +
                          (item.rating != null ? ' (${item.rating}⭐)' : ''),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                relTime,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
