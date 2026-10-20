import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import 'community_model.dart';
import 'community_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<CommunityPost> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final posts = await CommunityService.getPosts();
    if (mounted) {
      setState(() {
        _posts = posts;
        _loading = false;
      });
    }
  }

  void _openAddSheet() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(I18n.t('tt.community.loginRequired')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => _AddPostSheet(
        onAdded: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Text(I18n.t('tt.community.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: AppTheme.accentOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt),
        label: Text(I18n.t('tt.community.sharePlace')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🗺️', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      Text(
                        I18n.t('tt.community.empty'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        I18n.t('tt.community.emptyHint'),
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton.icon(
                        onPressed: _openAddSheet,
                        icon: const Icon(Icons.add_location_alt),
                        label: Text(I18n.t('tt.community.addPlace')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _posts.length,
                    itemBuilder: (context, i) =>
                        _PostCard(post: _posts[i], onDeleted: _load),
                  ),
                ),
    );
  }
}

// ─── Post Kartı ────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onDeleted;
  const _PostCard({required this.post, required this.onDeleted});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return I18n.tp('tt.community.minutesAgo', {'n': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) {
      return I18n.tp('tt.community.hoursAgo', {'n': '${diff.inHours}'});
    }
    return I18n.tp('tt.community.daysAgo', {'n': '${diff.inDays}'});
  }

  @override
  Widget build(BuildContext context) {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = myId == post.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl != null)
            Image.network(
              post.imageUrl!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        (post.userName.isNotEmpty
                                ? post.userName[0]
                                : '?')
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (post.cityName != null)
                            Text(
                              '📍 ${post.cityName}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isOwner)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () async {
                          await CommunityService.deletePost(post.id);
                          onDeleted();
                        },
                        tooltip: I18n.t('tt.community.delete'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (post.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    post.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  _timeAgo(post.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Paylaşım Formu ─────────────────────────────────────────────────

class _AddPostSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddPostSheet({required this.onAdded});

  @override
  State<_AddPostSheet> createState() => _AddPostSheetState();
}

class _AddPostSheetState extends State<_AddPostSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _cityCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(I18n.t('tt.community.nameRequired'))),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await CommunityService.addPost(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      cityName: _cityCtrl.text.trim(),
      imageUrl: _imageCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        widget.onAdded();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(I18n.t('tt.community.saveFailed')),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_location_alt, color: AppTheme.accentOrange),
                const SizedBox(width: 10),
                Text(
                  I18n.t('tt.community.sheetTitle'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: I18n.t('tt.community.nameLabel'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: I18n.t('tt.community.descLabel'),
                hintText: I18n.t('tt.community.descHint'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cityCtrl,
              decoration: InputDecoration(
                labelText: I18n.t('tt.community.cityLabel'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _imageCtrl,
              decoration: InputDecoration(
                labelText: I18n.t('tt.community.photoLabel'),
                hintText: 'https://...',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        I18n.t('tt.community.submit'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
