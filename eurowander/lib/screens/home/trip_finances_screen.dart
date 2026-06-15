import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/finance.dart';
import '../../models/saved_trip.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F5FF), Color(0xFFEDE7F6), Color(0xFFF3E5F5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                        : _error != null
                            ? _buildError()
                            : RefreshIndicator(
                                onRefresh: _loadData,
                                color: AppTheme.primaryColor,
                                child: _buildContent(),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseSheet,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Expense',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Finances',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text('Failed to load finances', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final summary = _summary!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 8),
        // Debts section - who owes whom
        if (summary.debts.isNotEmpty) ...[
          _buildSectionTitle('Settlements', Icons.swap_horiz_rounded),
          const SizedBox(height: 12),
          ...summary.debts.map(_buildDebtCard),
          const SizedBox(height: 24),
        ],
        // Balances section
        if (summary.balances.isNotEmpty) ...[
          _buildSectionTitle('Balances', Icons.account_balance_wallet_rounded),
          const SizedBox(height: 12),
          _buildBalancesCard(summary.balances),
          const SizedBox(height: 24),
        ],
        // Expenses list
        _buildSectionTitle('Expenses', Icons.receipt_long_rounded),
        const SizedBox(height: 12),
        if (summary.expenses.isEmpty)
          _buildEmptyExpenses()
        else
          ...summary.expenses.map(_buildExpenseCard),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildDebtCard(Debt debt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_forward_rounded, color: Colors.red.shade400, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.fromDisplayName,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                Text(
                  'owes ${debt.toDisplayName}',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                ),
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

  Widget _buildBalancesCard(List<Balance> balances) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    b.displayName,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
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

  Widget _buildExpenseCard(Expense expense) {
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
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDeleteExpense(expense),
      child: GestureDetector(
        onTap: expense.isManual ? () => _showEditExpenseSheet(expense) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: AppTheme.primaryColor.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isTicket ? const Color(0xFFF3E5F5) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isTicket ? Icons.flight_rounded : Icons.receipt_rounded,
                  size: 20,
                  color: isTicket ? AppTheme.primaryColor : Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.name,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Paid by ${_memberName(expense.paidBy)} · ${expense.eligibleMemberIds.length} member(s)',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_currencySymbol(expense.currency)}${expense.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                  Text(
                    DateFormat('MMM d').format(expense.createdAt),
                    style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              if (expense.isManual) ...[
                const SizedBox(width: 8),
                Icon(Icons.edit_outlined, size: 14, color: AppTheme.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyExpenses() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No expenses yet',
            style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Add Expense" to track spending',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
          ),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
            const SizedBox(height: 20),
            Text(
              _isEditing ? 'Edit Expense' : 'Add Expense',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 20),
            // Name field
            _buildTextField(_nameController, 'Expense name', Icons.label_outline_rounded),
            const SizedBox(height: 14),
            // Amount + currency row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(_amountController, 'Amount', Icons.attach_money_rounded,
                      keyboardType: TextInputType.numberWithOptions(decimal: true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F5FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currency,
                        isExpanded: true,
                        style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
                        items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _currency = v ?? 'EUR'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Paid by
            Text('Paid by', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.members.map((m) {
                final selected = _paidBy == m.userId;
                return GestureDetector(
                  onTap: () => setState(() => _paidBy = m.userId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryColor : const Color(0xFFF8F5FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      m.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Split between
            Text('Split between', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                      color: selected ? const Color(0xFF4CAF50) : const Color(0xFFF8F5FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected) ...[
                          const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          m.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryColor),
        filled: true,
        fillColor: const Color(0xFFF8F5FF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}
