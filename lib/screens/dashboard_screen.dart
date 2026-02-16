import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:random_avatar/random_avatar.dart';
import '../providers/user_provider.dart';
import '../services/contract_service.dart';
import '../services/budget_contract_service.dart';
import '../models/contract_model.dart';
import '../models/budget_contract_model.dart';
import '../widgets/contract_card.dart';
import 'create_contract_screen.dart';
import 'create_budget_contract_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onContractsTap;
  final VoidCallback? onBudgetsTap;

  const DashboardScreen({
    super.key,
    this.onContractsTap,
    this.onBudgetsTap,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _contractService = ContractService();
  final _budgetService = BudgetContractService();
  Stream<List<ContractModel>>? _contractStream;
  Stream<List<BudgetContractModel>>? _budgetStream;

  @override
  void initState() {
    super.initState();
    // Initialize streams once (same pattern as Contract module)
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id ?? '';
    _contractStream = _contractService.getAuthenticatedUserContracts(userId);
    _budgetStream = _budgetService.getAuthenticatedUserBudgetContracts(userId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    // Use cached streams initialized in initState (same pattern as Contract module)
    final contractStream = _contractStream ??
        _contractService.getAuthenticatedUserContracts(user?.id ?? '');
    final budgetStream = _budgetStream ??
        _budgetService.getAuthenticatedUserBudgetContracts(user?.id ?? '');

    final userAvatar = RandomAvatar(
      user?.fullName ?? 'User',
      trBackground: true,
      height: 50,
      width: 50,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 55, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green, Colors.green],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1.5),
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: userAvatar,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 14.0,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            user?.fullName ?? 'User',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        'Create Contract',
                        Iconsax.document_text,
                        Colors.blue,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CreateContractScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        context,
                        'Create Budget',
                        Iconsax.wallet_3,
                        Colors.blue,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CreateBudgetContractScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  StreamBuilder<List<ContractModel>>(
                    stream: contractStream,
                    builder: (context, contractSnapshot) {
                      return StreamBuilder<List<BudgetContractModel>>(
                        stream: budgetStream,
                        builder: (context, budgetSnapshot) {
                          final contracts = contractSnapshot.data ?? [];
                          final budgets = budgetSnapshot.data ?? [];

                          final activeContracts = contracts
                              .where((c) => c.status.toLowerCase() == 'active')
                              .length;
                          final activeBudgets = budgets
                              .where((b) =>
                                  b.status == BudgetContractStatus.active)
                              .length;
                          final depositedAmount = budgets.fold<double>(
                              0.0, (sum, b) => sum + b.fundedAmount);
                          // Withdrawn amount - currently not tracked in model, showing as 0
                          // TODO: Add withdrawnAmount field to BudgetContractModel
                          final withdrawnAmount = 0.0;

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      context,
                                      'Active Contracts',
                                      activeContracts.toString(),
                                      Iconsax.document_text,
                                      Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      context,
                                      'Active Budgets',
                                      activeBudgets.toString(),
                                      Iconsax.wallet_3,
                                      Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCardWithSummary(
                                      context,
                                      'Deposited Amount',
                                      'TSh ${depositedAmount.toStringAsFixed(0)}',
                                      'Total funds deposited',
                                      Iconsax.money_recive,
                                      Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCardWithSummary(
                                      context,
                                      'Withdrawn Amount',
                                      'TSh ${withdrawnAmount.toStringAsFixed(0)}',
                                      'Total funds withdrawn',
                                      Iconsax.money_send,
                                      Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Recent Contracts Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Contracts',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          fontSize: 18,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (widget.onContractsTap != null) {
                            widget.onContractsTap!();
                          }
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<ContractModel>>(
                    stream: contractStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final contracts = snapshot.data ?? [];
                      final recentContracts = contracts.take(2).toList();

                      if (recentContracts.isEmpty) {
                        return _buildEmptyState(
                          context,
                          'No contracts yet',
                          'Create your first contract to get started',
                          Iconsax.document_text,
                        );
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: recentContracts.map((contract) {
                            return Container(
                              width: MediaQuery.of(context).size.width * 0.85,
                              margin: const EdgeInsets.only(right: 12),
                              child: ContractCard(
                                contract: contract,
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Recent Budgets Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Budgets',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          fontSize: 18,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (widget.onBudgetsTap != null) {
                            widget.onBudgetsTap!();
                          }
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<BudgetContractModel>>(
                    stream: budgetStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final budgets = snapshot.data ?? [];
                      final recentBudgets = budgets.take(2).toList();

                      if (recentBudgets.isEmpty) {
                        return _buildEmptyState(
                          context,
                          'No budgets yet',
                          'Create your first budget contract to get started',
                          Iconsax.wallet_3,
                        );
                      }

                      return SizedBox(
                        height: 230,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          itemCount: recentBudgets.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: MediaQuery.of(context).size.width * 0.85,
                              margin: const EdgeInsets.only(right: 12),
                              child: _buildBudgetCard(
                                  context, recentBudgets[index]),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardWithSummary(
    BuildContext context,
    String label,
    String value,
    String summary,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBudgetDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Widget _buildBudgetCard(BuildContext context, BudgetContractModel budget) {
    final statusColor = BudgetContractModel.getStatusColor(budget.status);
    final statusText = BudgetContractModel.getStatusText(budget.status);
    final contractTypeText =
        BudgetContractModel.getContractTypeText(budget.contractType);
    final progress =
        budget.amount > 0 ? budget.fundedAmount / budget.amount : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Iconsax.wallet_3,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        budget.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Contract Type & Timer
            Row(
              children: [
                Row(
                  children: [
                    Icon(
                      budget.contractType == ContractType.negotiable
                          ? Iconsax.lock_1
                          : Iconsax.lock,
                      size: 14,
                      color: budget.contractType == ContractType.negotiable
                          ? Colors.orange
                          : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      contractTypeText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: budget.contractType == ContractType.negotiable
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                if (budget.contractEndDate != null &&
                    budget.remainingTime != null &&
                    budget.remainingTime! > Duration.zero) ...[
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.timer,
                        size: 14,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatBudgetDuration(budget.remainingTime!),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Funding Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Funding Progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TSh ${budget.fundedAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'TSh ${budget.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                // For Unfunded contracts: Always allow close/remove
                if (budget.status == BudgetContractStatus.unfunded) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddFundsDialog(context, budget),
                      icon: const Icon(Iconsax.add, size: 14),
                      label: const Text('Add Funds',
                          style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => _showCloseContractDialog(context, budget),
                    icon: const Icon(Iconsax.close_circle, size: 18),
                    color: Colors.red,
                    tooltip: 'Remove Contract',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ]
                // For Negotiable contracts: Can withdraw and close anytime
                else if (budget.contractType == ContractType.negotiable &&
                    budget.status == BudgetContractStatus.active) ...[
                  // Withdraw button (if has funds)
                  if (budget.fundedAmount > 0)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showWithdrawDialog(context, budget),
                        icon: const Icon(Iconsax.arrow_down_2, size: 14),
                        label: const Text('Withdraw',
                            style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  // Add Funds button (if not fully funded)
                  if (!budget.isFullyFunded) ...[
                    if (budget.fundedAmount > 0) const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddFundsDialog(context, budget),
                        icon: const Icon(Iconsax.add, size: 14),
                        label: const Text('Add Funds',
                            style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    // Close button
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () =>
                          _showCloseContractDialog(context, budget),
                      icon: const Icon(Iconsax.close_circle, size: 18),
                      color: Colors.red,
                      tooltip: 'Close Contract',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ]
                // For Non-Negotiable contracts: Standard behavior
                else ...[
                  if (!budget.isFullyFunded) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddFundsDialog(context, budget),
                        icon: const Icon(Iconsax.add, size: 14),
                        label: const Text('Add Funds',
                            style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    // Close button
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () =>
                          _showCloseContractDialog(context, budget),
                      icon: const Icon(Iconsax.close_circle, size: 18),
                      color: Colors.red,
                      tooltip: 'Remove Contract',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                  if (budget.isFullyFunded)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showWithdrawDialog(context, budget),
                        icon: const Icon(Iconsax.arrow_down_2, size: 14),
                        label: const Text('Withdraw',
                            style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, BudgetContractModel contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contract: ${contract.title}'),
            const SizedBox(height: 8),
            Text(
              'Available: TSh ${contract.fundedAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Amount to Withdraw',
                prefixText: 'TSh ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement withdraw functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funds withdrawn successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _showAddFundsDialog(BuildContext context, BudgetContractModel contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contract: ${contract.title}'),
            const SizedBox(height: 8),
            Text('Current: TSh ${contract.fundedAmount.toStringAsFixed(2)}'),
            Text('Target: TSh ${contract.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Amount to Add',
                prefixText: 'TSh ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement add funds functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funds added successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Funds'),
          ),
        ],
      ),
    );
  }

  void _showCloseContractDialog(
      BuildContext context, BudgetContractModel contract) {
    // Always allow closing unfunded contracts
    // Prevent closing if budget is 100% funded (except unfunded status)
    if (contract.status != BudgetContractStatus.unfunded &&
        contract.isFullyFunded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot close contract when budget is 100% funded'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Contract'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contract: ${contract.title}'),
            const SizedBox(height: 8),
            Text(
              'This will permanently close the contract.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            if (contract.fundedAmount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Available funds: TSh ${contract.fundedAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Funds will be returned to your account.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _budgetService.deleteBudgetContract(contract.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contract deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Failed to delete contract: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close Contract'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
