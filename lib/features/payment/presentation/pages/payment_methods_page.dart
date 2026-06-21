import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/saved_card.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final List<SavedCard> _cards = [];
  bool _isLoading = true;

  final _nameCtl = TextEditingController();
  final _numberCtl = TextEditingController();
  final _nicknameCtl = TextEditingController();
  String _selectedMonth = '01';
  String _selectedYear = '2026';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _numberCtl.dispose();
    _nicknameCtl.dispose();
    super.dispose();
  }

  void _deleteCard(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Card'),
        content: const Text('Are you sure you want to remove this card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _cards.removeWhere((c) => c.id == id));
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddCardSheet() {
    _nameCtl.clear();
    _numberCtl.clear();
    _nicknameCtl.clear();
    _selectedMonth = '01';
    _selectedYear = DateTime.now().year.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Card',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildSheetField('Cardholder Name', _nameCtl),
            const SizedBox(height: 12),
            _buildSheetField('Card Number', _numberCtl,
                maxLength: 19, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedMonth,
                    decoration: _sheetDecoration(),
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: (i + 1).toString().padLeft(2, '0'),
                        child: Text((i + 1).toString().padLeft(2, '0')),
                      ),
                    ),
                    onChanged: (v) => setState(() => _selectedMonth = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedYear,
                    decoration: _sheetDecoration(),
                    items: List.generate(
                      11,
                      (i) => DropdownMenuItem(
                        value: (DateTime.now().year + i).toString(),
                        child: Text((DateTime.now().year + i).toString()),
                      ),
                    ),
                    onChanged: (v) => setState(() => _selectedYear = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSheetField('Nickname (optional)', _nicknameCtl),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameCtl.text.trim().isEmpty || _numberCtl.text.trim().isEmpty) {
                    return;
                  }
                  final cleaned = _numberCtl.text.replaceAll(RegExp(r'\D'), '');
                  final last4 = cleaned.length >= 4 ? cleaned.substring(cleaned.length - 4) : cleaned;
                  final id = DateTime.now().millisecondsSinceEpoch.toString();
                  setState(() {
                    _cards.add(SavedCard(
                      id: id,
                      cardHolder: _nameCtl.text.trim(),
                      last4: last4,
                      expiryMonth: int.parse(_selectedMonth),
                      expiryYear: int.parse(_selectedYear),
                      nickname: _nicknameCtl.text.trim().isEmpty ? null : _nicknameCtl.text.trim(),
                    ));
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Card',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Payment Methods',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _cards.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cards.length,
                  itemBuilder: (_, i) => _buildCardItem(_cards[i]),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCardSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(
                Icons.credit_card_outlined,
                size: 40,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No saved cards',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a card to pay faster',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _showAddCardSheet,
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              label: const Text(
                'Add Card',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(SavedCard card) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.credit_card,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.nickname ?? card.cardHolder,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.maskedNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Expires ${card.formattedExpiry}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.textHint),
                onPressed: () => _deleteCard(card.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetField(String label, TextEditingController ctl,
      {int? maxLength, TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctl,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        counterText: '',
      ),
    );
  }

  InputDecoration _sheetDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
