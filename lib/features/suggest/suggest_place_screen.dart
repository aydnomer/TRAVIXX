import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/database_service.dart';
import '../cities/city_model.dart';

/// Kullanıcının yeni mekan önerebileceği form.
/// Supabase'de place_suggestions tablosuna kaydedilir (status='pending').
/// Admin sonradan onaylayıp places tablosuna geçirir.
class SuggestPlaceScreen extends StatefulWidget {
  const SuggestPlaceScreen({super.key});

  @override
  State<SuggestPlaceScreen> createState() => _SuggestPlaceScreenState();
}

class _SuggestPlaceScreenState extends State<SuggestPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  List<City> _cities = const [];
  City? _selectedCity;
  String _selectedCategory = 'Tarihi';
  bool _loading = true;
  bool _submitting = false;

  static const _categories = [
    'Tarihi',
    'Müze',
    'Doğa',
    'Kültür',
    'Dini',
    'Manzara',
    'Alışveriş',
  ];

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await DatabaseService.getCities();
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity == null) {
      _snack(I18n.t('suggest.selectCity'), isError: true);
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _snack(I18n.t('suggest.loginRequired'), isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      await Supabase.instance.client.from('place_suggestions').insert({
        'user_id': user.id,
        'user_email': user.email,
        'city_id': _selectedCity!.id,
        'name': _nameCtrl.text.trim(),
        'category': _selectedCategory,
        'description': _descCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'status': 'pending',
      });
      if (!mounted) return;
      _snack(I18n.t('suggest.thankYou'), isError: false);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        context.canPop() ? context.pop() : context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        _snack('${I18n.t('auth.genericError')}: $e', isError: true);
        setState(() => _submitting = false);
      }
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(I18n.t('suggest.title')),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoBanner(),
                    const SizedBox(height: 20),
                    _label(I18n.t('suggest.placeName')),
                    _input(
                      _nameCtrl,
                      hint: 'Örn: Sümela Manastırı',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? I18n.t('suggest.required')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _label(I18n.t('suggest.city')),
                    _cityDropdown(),
                    const SizedBox(height: 16),
                    _label(I18n.t('suggest.category')),
                    _categoryDropdown(),
                    const SizedBox(height: 16),
                    _label(I18n.t('suggest.address')),
                    _input(
                      _addressCtrl,
                      hint: 'Örn: Sultanahmet Mh., Fatih/İstanbul',
                    ),
                    const SizedBox(height: 16),
                    _label(I18n.t('suggest.description')),
                    _input(
                      _descCtrl,
                      hint: I18n.t('suggest.descHint'),
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().length < 10)
                          ? I18n.t('suggest.descTooShort')
                          : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, size: 18),
                        label: Text(
                          _submitting
                              ? I18n.t('common.loading')
                              : I18n.t('suggest.submit'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.accentOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              I18n.t('suggest.info'),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _input(
    TextEditingController c, {
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentOrange, width: 2),
        ),
      ),
    );
  }

  Widget _cityDropdown() {
    return DropdownButtonFormField<City>(
      initialValue: _selectedCity,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
      ),
      hint: Text(I18n.t('suggest.selectCity')),
      items: _cities
          .map((c) => DropdownMenuItem(
                value: c,
                child: Row(
                  children: [
                    Text(c.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(c.name),
                  ],
                ),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedCity = v),
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
      ),
      items: _categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) =>
          setState(() => _selectedCategory = v ?? 'Tarihi'),
    );
  }
}
