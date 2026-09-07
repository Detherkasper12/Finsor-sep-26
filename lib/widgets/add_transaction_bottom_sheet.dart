import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import '../providers/categories_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/categorization_provider.dart';
import '../services/categorization/categorization_service.dart';
import '../constants/app_theme.dart';
import '../utils/category_icon_mapper.dart';
import '../utils/safe_json_parse.dart';
import '../screens/add_transaction/transaction_entry_screen.dart';

class AddTransactionBottomSheet extends ConsumerStatefulWidget {
  final TransactionType initialType;
  final String? initialCategoryId;
  final String? initialWalletId;
  final String? initialAmount;
  final String? initialDescription;
  final DateTime? initialDate;
  final String? initialToWalletId;

  const AddTransactionBottomSheet({
    super.key,
    this.initialType = TransactionType.expense,
    this.initialCategoryId,
    this.initialWalletId,
    this.initialAmount,
    this.initialDescription,
    this.initialDate,
    this.initialToWalletId,
  });

  @override
  ConsumerState<AddTransactionBottomSheet> createState() => _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends ConsumerState<AddTransactionBottomSheet>
    with TickerProviderStateMixin {
  
  late TransactionType _selectedType;
  late TabController _typeTabController;
  
  String _amount = '';
  String? _selectedCategoryId;
  String? _selectedWalletId;
  String? _selectedToWalletId; // For transfers
  String _description = '';
  DateTime _selectedDate = DateTime.now();
  
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _descriptionFocus = FocusNode();
  
  bool _isLoading = false;
  bool _isRecurring = false;
  RecurringFrequency _recurringFrequency = RecurringFrequency.monthly;
  int _recurringInterval = 1;

  String? _suggestedCategoryId;
  CategorizationSource? _categorizationSource;
  bool _userPickedCategory = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedCategoryId = widget.initialCategoryId;
    _selectedWalletId = widget.initialWalletId;
    _selectedToWalletId = widget.initialToWalletId;
    if (widget.initialAmount != null && widget.initialAmount!.isNotEmpty) {
      _amount = widget.initialAmount!;
    }
    if (widget.initialDescription != null && widget.initialDescription!.isNotEmpty) {
      _description = widget.initialDescription!;
      _descriptionController.text = widget.initialDescription!;
    }
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyLastUsedDefaults());
    _typeTabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _selectedType.index,
    );
    
    _typeTabController.addListener(() {
      if (_typeTabController.indexIsChanging) {
        setState(() {
          _selectedType = TransactionType.values[_typeTabController.index];
          _selectedCategoryId = null;
          _suggestedCategoryId = null;
          _categorizationSource = null;
          _userPickedCategory = false;
        });
      }
    });
  }

  Future<void> _applyLastUsedDefaults() async {
    if (_selectedWalletId != null && _selectedCategoryId != null) return;
    final settings = await ref.read(settingsProvider.future);
    final prefs = settings.preferences;
    if (_selectedWalletId == null) {
      final last = safeString(prefs['lastUsedWalletId']);
      if (last != null && last.isNotEmpty && mounted) setState(() => _selectedWalletId = last);
    }
    if (_selectedCategoryId == null) {
      final last = safeString(prefs['lastUsedCategoryId_${_selectedType.name}']);
      if (last != null && last.isNotEmpty && mounted) setState(() => _selectedCategoryId = last);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _typeTabController.dispose();
    _descriptionController.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  void _onDescriptionChanged(String value) {
    _description = value;
    _debounceTimer?.cancel();
    if (_selectedType == TransactionType.transfer) return;
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final service = ref.read(categorizationServiceProvider);
      if (!mounted) return;
      final result = await service.suggest(
        description: value.trim(),
        transactionType: _selectedType,
      );
      if (!mounted || _userPickedCategory) return;
      if (result.categoryId != null) {
        setState(() {
          _suggestedCategoryId = result.categoryId;
          _selectedCategoryId = result.categoryId;
          _categorizationSource = result.source == CategorizationSource.local ? CategorizationSource.local : null;
        });
      } else {
        setState(() {
          _suggestedCategoryId = null;
          _categorizationSource = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);
    final wallets = walletsAsync.valueOrNull ?? [];
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];
    final filteredCategories = categories
        .where((c) => c.type == _selectedType && c.parentId == null)
        .toList();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
        minHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.1),
            blurRadius: isDark ? 20 : 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          _buildHandleBar(),
          
          // Header with type tabs
          _buildHeader(),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 0, 16, keyboardHeight + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWalletSection(wallets),
                  const Gap(24),
                  _buildCategorySection(filteredCategories),
                  if (_selectedType == TransactionType.transfer) ...[
                    const Gap(24),
                    _buildToWalletSection(wallets),
                  ],
                  const Gap(32),
                  _buildContinueButton(wallets),
                  const Gap(32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandleBar() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 50,
      height: 5,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Add Transaction',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _typeTabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Income'),
                Tab(text: 'Expense'),
                Tab(text: 'Transfer'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Kept for possible quick-add or legacy entry
  // ignore: unused_element
  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _getTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _getTypeColor().withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                _amount.isEmpty ? '\$0.00' : '\$${_formatAmount(_amount)}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _getTypeColor(),
                ),
              ),
              const Gap(16),
              _buildKeypad(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          children: [
            _buildKeypadButton('1'),
            _buildKeypadButton('2'),
            _buildKeypadButton('3'),
          ],
        ),
        const Gap(8),
        Row(
          children: [
            _buildKeypadButton('4'),
            _buildKeypadButton('5'),
            _buildKeypadButton('6'),
          ],
        ),
        const Gap(8),
        Row(
          children: [
            _buildKeypadButton('7'),
            _buildKeypadButton('8'),
            _buildKeypadButton('9'),
          ],
        ),
        const Gap(8),
        Row(
          children: [
            _buildKeypadButton('.'),
            _buildKeypadButton('0'),
            _buildKeypadButton('⌫', isBackspace: true),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String value, {bool isBackspace = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onKeypadTap(value, isBackspace),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isBackspace ? Colors.red : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryTreeChips(List<Category> categories) {
    final roots = categories.where((c) => c.parentId == null).toList();
    final list = <Widget>[];
    for (final root in roots) {
      list.add(_categoryChip(root));
      final children = categories.where((c) => c.parentId == root.id).toList();
      for (final child in children) {
        list.add(Padding(
          padding: const EdgeInsets.only(left: 20),
          child: _categoryChip(child),
        ));
      }
    }
    return list;
  }

  Widget _categoryChip(Category category) {
    final isSelected = _selectedCategoryId == category.id;
    final categoryColor = Color(int.parse((category.color).replaceAll('#', '0xFF')));
    final isAuto = _suggestedCategoryId == category.id && _categorizationSource != null;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = category.id;
          _userPickedCategory = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? categoryColor : categoryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: categoryColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(category.iconName),
              color: isSelected ? Colors.white : categoryColor,
              size: 20,
            ),
            const Gap(8),
            Text(
              category.name,
              style: TextStyle(
                color: isSelected ? Colors.white : categoryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isAuto) ...[
              const Gap(4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isSelected ? Colors.white24 : categoryColor.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Auto (Local)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white70 : categoryColor.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(List<Category> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(12),
        if (categories.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No categories available for ${_selectedType.name}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildCategoryTreeChips(categories),
          ),
      ],
    );
  }

  Widget _buildWalletSection(List<Wallet> wallets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedType == TransactionType.transfer ? 'From Wallet' : 'Wallet',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(12),
        _buildWalletSelector(wallets, _selectedWalletId, (walletId) {
          setState(() {
            _selectedWalletId = walletId;
          });
        }),
      ],
    );
  }

  Widget _buildToWalletSection(List<Wallet> wallets) {
    final availableWallets = wallets.where((w) => w.id != _selectedWalletId).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'To Wallet',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(12),
        _buildWalletSelector(availableWallets, _selectedToWalletId, (walletId) {
          setState(() {
            _selectedToWalletId = walletId;
          });
        }),
      ],
    );
  }

  Widget _buildWalletSelector(List<Wallet> wallets, String? selectedId, Function(String) onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: wallets.map((wallet) {
        final isSelected = selectedId == wallet.id;
        final walletColor = Color(int.parse((wallet.color ?? '#4CAF50').replaceAll('#', '0xFF')));
        
        return GestureDetector(
          onTap: () => onSelect(wallet.id),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? walletColor : walletColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: walletColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _getWalletIcon(wallet.type),
                  color: isSelected ? Colors.white : walletColor,
                  size: 24,
                ),
                const Gap(4),
                Text(
                  wallet.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : walletColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(wallet.currentBalance),
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : walletColor.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ignore: unused_element
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(12),
        TextField(
          controller: _descriptionController,
          focusNode: _descriptionFocus,
          decoration: InputDecoration(
            hintText: 'Enter description...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 2,
          onChanged: _onDescriptionChanged,
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(12),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                const Gap(12),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(List<Wallet> wallets) {
    final canContinue = _selectedWalletId != null &&
        (_selectedType != TransactionType.transfer
            ? _selectedCategoryId != null
            : _selectedToWalletId != null);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canContinue ? _onContinue : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getTypeColor(),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          'Continue',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _onContinue() {
    if (_selectedWalletId == null) return;
    if (_selectedType != TransactionType.transfer && _selectedCategoryId == null) return;
    if (_selectedType == TransactionType.transfer && _selectedToWalletId == null) return;
    final navigator = Navigator.of(context);
    final type = _selectedType;
    final walletId = _selectedWalletId!;
    final categoryId = _selectedType == TransactionType.transfer ? 'transfer' : _selectedCategoryId!;
    final toWalletId = _selectedToWalletId;
    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => TransactionEntryScreen(
          type: type,
          walletId: walletId,
          categoryId: categoryId,
          toWalletId: toWalletId,
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSaveButton() {
    final canSave = _amount.isNotEmpty &&
                   _selectedWalletId != null &&
                   (_selectedType != TransactionType.transfer
                       ? _selectedCategoryId != null
                       : _selectedToWalletId != null);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSave && !_isLoading ? _saveTransaction : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getTypeColor(),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Text(
                'Add ${_selectedType.name.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildRepeatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Repeat', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: _isRecurring
              ? Text(_recurringInterval == 1
                  ? _recurringFrequency.name[0].toUpperCase() + _recurringFrequency.name.substring(1)
                  : 'Every $_recurringInterval ${_recurringFrequency.name}')
              : null,
          value: _isRecurring,
          onChanged: (v) => setState(() => _isRecurring = v),
        ),
        if (_isRecurring) ...[
          const Gap(8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<RecurringFrequency>(
                  value: _recurringFrequency,
                  decoration: InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: RecurringFrequency.values.map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.name[0].toUpperCase() + f.name.substring(1)),
                  )).toList(),
                  onChanged: (v) => setState(() => _recurringFrequency = v!),
                ),
              ),
              const Gap(12),
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: '$_recurringInterval',
                  decoration: InputDecoration(
                    labelText: 'Every',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null && n > 0) setState(() => _recurringInterval = n);
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Color _getTypeColor() {
    switch (_selectedType) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
    }
  }

  String _formatAmount(String amount) {
    if (amount.isEmpty) return '0.00';
    
    // Remove any non-digit characters except decimal point
    final cleanAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
    
    // Parse as double and format
    final double? value = double.tryParse(cleanAmount);
    if (value == null) return '0.00';
    
    return NumberFormat('#,##0.00').format(value);
  }

  void _onKeypadTap(String value, bool isBackspace) {
    HapticFeedback.lightImpact();
    
    setState(() {
      if (isBackspace) {
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else {
        // Prevent multiple decimal points
        if (value == '.' && _amount.contains('.')) return;
        
        // Limit to reasonable amount length
        if (_amount.length < 10) {
          _amount += value;
        }
      }
    });
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    
    if (date != null) {
      if (!mounted) return;
      
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveTransaction() async {
    if (_selectedWalletId == null) {
      HapticFeedback.lightImpact();
      return;
    }
    if (_selectedType != TransactionType.transfer && _selectedCategoryId == null) return;
    if (_selectedType == TransactionType.transfer && _selectedToWalletId == null) return;
    
    // Haptic feedback for save action
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.tryParse(_amount) ?? 0;
      if (amount <= 0) {
        _showError('Please enter a valid amount');
        return;
      }

      final categoryId = _selectedType == TransactionType.transfer ? 'transfer' : _selectedCategoryId!;
      String? recurringId;

      if (_isRecurring) {
        final rtId = 'rec_${const Uuid().v4()}';
        recurringId = rtId;
        final rt = RecurringTransaction(
          id: rtId,
          amount: amount,
          type: _selectedType,
          categoryId: categoryId,
          walletId: _selectedWalletId!,
          toWalletId: _selectedToWalletId,
          description: _description.isEmpty ? null : _description,
          frequency: _recurringFrequency,
          interval: _recurringInterval,
          startDate: _selectedDate,
          nextRunDate: _computeFirstNextRun(_selectedDate, _recurringFrequency, _recurringInterval),
          createdAt: DateTime.now(),
        );
        await ref.read(recurringNotifierProvider.notifier).addRecurring(rt);
      }

      final transaction = Transaction(
        id: const Uuid().v4(),
        amount: amount,
        type: _selectedType,
        categoryId: categoryId,
        walletId: _selectedWalletId!,
        toWalletId: _selectedToWalletId,
        description: _description.isEmpty ? null : _description,
        createdAt: _selectedDate,
        recurringId: recurringId,
      );

      await ref.read(transactionNotifierProvider.notifier).addTransaction(transaction);
      ref.read(settingsNotifierProvider.notifier).updateLastUsedTransactionDefaults(
        walletId: _selectedWalletId!,
        categoryId: categoryId,
        type: _selectedType.name,
      );
      
      if (mounted) {
        // Success haptic feedback
        HapticFeedback.heavyImpact();
        
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('${_selectedType.name.toUpperCase()} added successfully!'),
              ],
            ),
            backgroundColor: _getTypeColor(),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to add transaction: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  DateTime _computeFirstNextRun(DateTime start, RecurringFrequency freq, int interval) {
    switch (freq) {
      case RecurringFrequency.daily:
        return start.add(Duration(days: interval));
      case RecurringFrequency.weekly:
        return start.add(Duration(days: 7 * interval));
      case RecurringFrequency.monthly:
        var m = start.month + interval;
        var y = start.year;
        while (m > 12) { m -= 12; y++; }
        return DateTime(y, m, start.day.clamp(1, DateTime(y, m + 1, 0).day));
      case RecurringFrequency.yearly:
        return DateTime(start.year + interval, start.month, start.day);
    }
  }

  IconData _getCategoryIcon(String iconName) => CategoryIcons.fromName(iconName);

  IconData _getWalletIcon(WalletType type) => CategoryIcons.walletIcon(type.name);
}
