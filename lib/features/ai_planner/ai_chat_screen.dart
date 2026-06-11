import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ai_planner_service.dart';
import '../places/place_model.dart';

/// AI Gezi Planlayıcı — chat tarzı arayüz.
/// Kullanıcı "İstanbul'da 2 gün" yazınca rota üretilir.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    // Açılışta karşılama mesajı
    _messages.add(_ChatMessage.assistant(
      I18n.t('ai.welcome'),
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final query = text.trim();
    if (query.isEmpty || _processing) return;

    setState(() {
      _messages.add(_ChatMessage.user(query));
      _processing = true;
      _inputCtrl.clear();
    });
    _scrollToBottom();

    final plan = await AiPlannerService.plan(query);

    if (!mounted) return;
    setState(() {
      _processing = false;
      if (plan == null) {
        _messages.add(_ChatMessage.assistant(I18n.t('ai.cantUnderstand')));
      } else if (plan.itinerary.isEmpty) {
        _messages.add(_ChatMessage.assistant(I18n.t('ai.noPlaces')));
      } else {
        _messages.add(_ChatMessage.plan(plan));
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('🤖', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Text(I18n.t('ai.title')),
          ],
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Hızlı öneri chip'leri
          if (_messages.length == 1) _buildSuggestions(),
          // Mesaj listesi
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_processing ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length && _processing) {
                  return const _TypingIndicator();
                }
                return _MessageBubble(message: _messages[i]);
              },
            ),
          ),
          // Input
          _buildInput(),
        ],
      ),
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      'İstanbul 2 gün',
      'Antalya hafta sonu',
      'Kapadokya 3 gün',
      'İzmir 2 günlük',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) => ActionChip(
            label: Text(suggestions[i]),
            onPressed: () => _send(suggestions[i]),
            backgroundColor: Colors.white,
            side: BorderSide(
                color: AppTheme.accentOrange.withValues(alpha: 0.3)),
            labelStyle: const TextStyle(
              fontSize: 12,
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                onSubmitted: _send,
                enabled: !_processing,
                decoration: InputDecoration(
                  hintText: I18n.t('ai.inputHint'),
                  hintStyle: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppTheme.accentOrange,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _processing ? null : () => _send(_inputCtrl.text),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: const Icon(Icons.send,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bir chat mesajı (kullanıcı, asistan, veya plan kartı)
class _ChatMessage {
  final _ChatRole role;
  final String? text;
  final TripPlan? plan;

  _ChatMessage.user(this.text)
      : role = _ChatRole.user,
        plan = null;
  _ChatMessage.assistant(this.text)
      : role = _ChatRole.assistant,
        plan = null;
  _ChatMessage.plan(TripPlan p)
      : role = _ChatRole.assistant,
        plan = p,
        text = null;
}

enum _ChatRole { user, assistant }

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _ChatRole.user;
    final isPlan = message.plan != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: isPlan
                ? _PlanCard(plan: message.plan!)
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: isUser
                          ? null
                          : Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Text(
                      message.text ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.white : AppTheme.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final TripPlan plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(plan.city.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.city.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      plan.summary,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...plan.itinerary.map((day) => _DayBlock(day: day)),
        ],
      ),
    );
  }
}

class _DayBlock extends StatelessWidget {
  final TripDay day;
  const _DayBlock({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${I18n.t('ai.day')} ${day.dayNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...day.places.asMap().entries.map((e) => _PlaceRow(
                slotLabel: day.slotLabel(e.key),
                place: e.value,
              )),
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  final String slotLabel;
  final Place place;
  const _PlaceRow({required this.slotLabel, required this.place});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/place/${place.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(place.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slotLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
    );
  }
}
