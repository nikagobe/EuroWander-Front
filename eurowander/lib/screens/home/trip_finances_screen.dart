import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/finance.dart';
import '../../models/saved_trip.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

class TripFinancesScreen extends StatefulWidget {
  final SavedTrip trip;

  const TripFinancesScreen({super.key, required this.trip});

  @override
  State<TripFinancesScreen> createState() => _TripFinancesScreenState();
}

class _TripFinancesScreenState extends State<TripFinancesScreen> {
  final ApiService _apiService = ApiService();
  FinanceSummary? _summary;
  List<TripMember> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _apiService.getFinanceSummary(token: token, tripId: widget.trip.id),
        _apiService.getTripMembers(token: token, tripId: widget.trip.id),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as FinanceSummary;
        _members = results[1] as List<TripMember>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _memberName(String userId) {
    final member = _members.where((m) => m.userId == userId).firstOrNull;
    return member?.displayName ?? userId.substring(0, 6);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
      child: Column(
        children: [
          const EWAppBar(title: 'Finances'),
          Expanded(
            child: _isLoading
                ? const ShimmerList()
                : _error != null
                    ? _buildError(context)
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.brandPrimary,
                        child: _buildContent(context),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
          const SizedBox(height: AppSpacing.sm),
          Text('Failed to load finances', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final summary = _summary!;
    return ListView(
      padding: AppSpacing.paddingHorizontalXl,
      children: [
        const SizedBox(height: AppSpacing.xs),
        // Debts section - who owes whom
        if (summary.debts.isNotEmpty) ...[
          _buildSectionTitle(context, 'Settlements', Icons.swap_horiz_rounded),
          const SizedBox(height: AppSpacing.sm),
          ...summary.debts.map((d) => _buildDebtCard(context, d)),
          const SizedBox(height: AppSpacing.xl),
        ],
        // Balances section
        if (summary.balances.isNotEmpty) ...[
          _buildSectionTitle(context, 'Balances', Icons.account_balance_wallet_rounded),
          const SizedBox(height: AppSpacing.sm),
          _buildBalancesCard(context, summary.balances),
          const SizedBox(height: AppSpacing.xl),
        ],
        // Expenses list
        _buildSectionTitle(context, 'Expenses', Icons.receipt_long_rounded),
        const SizedBox(height: AppSpacing.sm),
        if (summary.expenses.isEmpty)
          _buildEmptyExpenses(context)
        else
          ...summary.expenses.map((e) => _buildExpenseCard(context, e)),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.brandPrimary),
        const SizedBox(width: AppSpacing.xs),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildDebtCard(BuildContext context, Debt debt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.ew.cardColor,
        borderRadius: AppRadius.borderLg,
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: AppRadius.borderMd,
            ),
            child: Icon(Icons.arrow_forward_rounded, color: Colors.red.shade400, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(debt.fromDisplayName, style: Theme.of(context).textTheme.labelLarge),
                Text('owes ${debt.toDisplayName}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            '${_currencySymbol(debt.currency)}${debt.amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade600),
          ),
        ],
      ),
    );
  }

  String _currencySymbol(String currency) {
    switch (currency) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'GEL':
        return '₾';
      default:
        return '$currency ';
    }
  }

  Widget _buildBalancesCard(BuildContext context, List<Balance> balances) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.ew.cardColor,
        borderRadius: AppRadius.borderLg,
        boxShadow: [
          BoxShadow(color: AppColors.brandPrimary.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: balances.map((b) {
          final overallPositive = b.netByCurrency.any((c) => c.netAmount > 0);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: overallPositive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      b.firstName.isNotEmpty ? b.firstName[0].toUpperCase() : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: overallPositive ? Colors.green.shade600 : Colors.red.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    b.displayName,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: context.ew.textPrimary),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: b.netByCurrency.map((ca) {
                    final isPositive = ca.netAmount >= 0;
                    return Text(
                      '${isPositive ? '+' : ''}${_currencySymbol(ca.currency)}${ca.netAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? Colors.green.shade600 : Colors.red.shade600,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, Expense expense) {
    final isTicket = expense.isTicket;

    return Dismissible(
      key: Key(expense.id),
      direction: expense.isManual ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: AppRadius.borderLg,
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDeleteExpense(expense),
      child: GestureDetector(
        onTap: expense.isManual ? () => _showEditExpenseSheet(expense) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.ew.cardColor,
            borderRadius: AppRadius.borderLg,
            boxShadow: [
              BoxShadow(color: AppColors.brandPrimary.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isTicket ? const Color(0xFFF3E5F5) : const Color(0xFFE8F5E9),
                  borderRadius: AppRadius.borderMd,
                ),
                child: Icon(
                  isTicket ? Icons.flight_rounded : Icons.receipt_rounded,
                  size: 20,
                  color: isTicket ? AppColors.brandPrimary : Colors.green.shade600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.name,
                      style: Theme.of(context).textTheme.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Paid by ${_memberName(expense.paidBy)} · ${expense.eligibleMemberIds.length} member(s)',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_currencySymbol(expense.currency)}${expense.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
                  ),
                  Text(
                    DateFormat('MMM d').format(expense.createdAt),
                    style: GoogleFonts.poppins(fontSize: 10, color: context.ew.textSecondary),
                  ),
                ],
              ),
              if (expense.isManual) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.edit_outlined, size: 14, color: context.ew.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyExpenses(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: context.ew.cardColor,
        borderRadius: AppRadius.borderLg,
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: AppSpacing.sm),
          Text('No expenses yet', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text('Tap "Add Expense" to track spending', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Future<bool> _confirmDeleteExpense(Expense expense) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return false;
    try {
      await _apiService.deleteExpense(token: token, tripId: widget.trip.id, expenseId: expense.id);
      _loadData();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red.shade600),
      );
      return false;
    }
  }

  void _showAddExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExpenseSheet(
        members: _members,
        tripId: widget.trip.id,
        onAdded: _loadData,
      ),
    );
  }

  void _showEditExpenseSheet(Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExpenseSheet(
        members: _members,
        tripId: widget.trip.id,
        onAdded: _loadData,
        editingExpense: expense,
      ),
    );
  }
}

// ─── Add Expense Bottom Sheet ─────────────────────────────────────────

class _AddExpenseSheet extends StatefulWidget {
  final List<TripMember> members;
  final String tripId;
  final VoidCallback onAdded;
  final Expense? editingExpense;

  const _AddExpenseSheet({
    required this.members,
    required this.tripId,
    required this.onAdded,
    this.editingExpense,
  });

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _currency = 'EUR';
  String? _paidBy;
  final Set<String> _selectedMembers = {};
  bool _isSaving = false;

  bool get _isEditing => widget.editingExpense != null;

  final _currencies = ['EUR', 'USD', 'GBP', 'GEL', 'CHF', 'CZK', 'PLN', 'HUF', 'SEK', 'NOK', 'DKK'];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.editingExpense!;
      _nameController.text = e.name;
      _amountController.text = e.amount.toStringAsFixed(2);
      _currency = e.currency;
      _paidBy = e.paidBy;
      _selectedMembers.addAll(e.eligibleMemberIds);
    } else {
      // Default: select all members
      for (final m in widget.members) {
        _selectedMembers.add(m.userId);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amountStr = _amountController.text.trim();
    if (name.isEmpty || amountStr.isEmpty || _paidBy == null || _selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    setState(() => _isSaving = true);
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      if (_isEditing) {
        await ApiService().editExpense(
          token: token,
          tripId: widget.tripId,
          expenseId: widget.editingExpense!.id,
          name: name,
          amount: amount,
          currency: _currency,
          paidBy: _paidBy!,
          eligibleMemberIds: _selectedMembers.toList(),
        );
      } else {
        await ApiService().addExpense(
          token: token,
          tripId: widget.tripId,
          name: name,
          amount: amount,
          currency: _currency,
          paidBy: _paidBy!,
          eligibleMemberIds: _selectedMembers.toList(),
        );
      }
      if (!mounted) return;
      widget.onAdded();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade600),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: context.ew.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: AppSpacing.lg),
            Text(
              _isEditing ? 'Edit Expense' : 'Add Expense',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Name field
            _buildTextField(_nameController, 'Expense name', Icons.label_outline_rounded),
            const SizedBox(height: 14),
            // Amount + currency row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(_amountController, 'Amount', Icons.attach_money_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.lightSurfaceVariant,
                      borderRadius: AppRadius.borderLg,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currency,
                        isExpanded: true,
                        style: GoogleFonts.poppins(fontSize: 14, color: context.ew.textPrimary),
                        items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _currency = v ?? 'EUR'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Paid by
            Text('Paid by', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: context.ew.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: widget.members.map((m) {
                final selected = _paidBy == m.userId;
                return GestureDetector(
                  onTap: () => setState(() => _paidBy = m.userId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.brandPrimary : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      m.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : context.ew.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Split between
            Text('Split between', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: context.ew.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: widget.members.map((m) {
                final selected = _selectedMembers.contains(m.userId);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedMembers.remove(m.userId);
                      } else {
                        _selectedMembers.add(m.userId);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.success : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected) ...[
                          const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: AppSpacing.xxs),
                        ],
                        Text(
                          m.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : context.ew.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isEditing ? 'Update Expense' : 'Save Expense', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: context.ew.textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: AppColors.brandPrimary),
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(borderRadius: AppRadius.borderLg, borderSide: BorderSide.none),
      ),
    );
  }
}



