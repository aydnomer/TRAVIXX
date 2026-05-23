import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import 'collection_card.dart';
import 'collection_model.dart';
import 'collection_service.dart';

/// Tüm tematik koleksiyonları liste halinde gösterir.
class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  List<PlaceCollection> _collections = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await CollectionService.getCollections();
    if (!mounted) return;
    setState(() {
      _collections = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(I18n.t('collections.title')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _collections.isEmpty
              ? Center(
                  child: Text(I18n.t('collections.empty')),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _collections.length,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CollectionCard(
                          collection: _collections[i],
                          large: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
