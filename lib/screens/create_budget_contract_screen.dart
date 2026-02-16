// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_text_field.dart';
import '../services/budget_contract_service.dart';
import '../models/budget_contract_model.dart';
import '../utils/custom_snackbar.dart';

class CreateBudgetContractScreen extends StatefulWidget {
  const CreateBudgetContractScreen({super.key});

  @override
  State<CreateBudgetContractScreen> createState() =>
      _CreateBudgetContractScreenState();
}

class _CreateBudgetContractScreenState extends State<CreateBudgetContractScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  ContractType _selectedContractType = ContractType.negotiable;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  // Contract term picker values (for non-negotiable contracts)
  int _selectedContractDays = 0;
  int _selectedContractHours = 0;
  int _selectedContractMinutes = 0;
  final _budgetContractService = BudgetContractService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _createBudgetContract() async {
    if (_formKey.currentState!.validate()) {
      // Validate contract term for non-negotiable contracts
      if (_selectedContractType == ContractType.nonNegotiable) {
        if (_selectedContractDays == 0 &&
            _selectedContractHours == 0 &&
            _selectedContractMinutes == 0) {
          CustomSnackBar.show(
            context: context,
            message: 'Please select contract term duration',
            type: SnackBarType.error,
          );
          return;
        }
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final user = Provider.of<UserProvider>(context, listen: false).user!;

        // Contract term: Used to calculate when contract can be closed (for non-negotiable)
        Duration? contractTerm;
        if (_selectedContractType == ContractType.nonNegotiable) {
          if (_selectedContractDays > 0 ||
              _selectedContractHours > 0 ||
              _selectedContractMinutes > 0) {
            contractTerm = Duration(
              days: _selectedContractDays,
              hours: _selectedContractHours,
              minutes: _selectedContractMinutes,
            );
          }
        }

        await _budgetContractService.createBudgetContract(
          userId: user.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          contractType: _selectedContractType,
          userFullName: user.fullName,
          userPhone: user.phone,
          contractTerm: contractTerm,
        );

        if (mounted) {
          CustomSnackBar.show(
            context: context,
            message: 'Budget contract created successfully',
            type: SnackBarType.success,
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(
            context: context,
            message: e.toString(),
            type: SnackBarType.error,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Create Budget Contract',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.grey[700],
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey[300]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contract Type Selection
                Text(
                  'Contract Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.green[700],
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose whether the contract can be terminated early',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildContractTypeOption(
                        'Negotiable',
                        'Flexible - can be closed anytime',
                        Iconsax.lock_1,
                        ContractType.negotiable,
                        _selectedContractType == ContractType.negotiable,
                        () {
                          setState(() {
                            _selectedContractType = ContractType.negotiable;
                            // Reset contract term when switching to negotiable
                            _selectedContractDays = 0;
                            _selectedContractHours = 0;
                            _selectedContractMinutes = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildContractTypeOption(
                        'Non-Negotiable',
                        'Fixed term - cannot be terminated',
                        Iconsax.lock,
                        ContractType.nonNegotiable,
                        _selectedContractType == ContractType.nonNegotiable,
                        () {
                          setState(() {
                            _selectedContractType = ContractType.nonNegotiable;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                // Contract Term (only for non-negotiable)
                if (_selectedContractType == ContractType.nonNegotiable) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Iconsax.timer,
                                color: Colors.orange[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Contract Term',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Duration in days (contract cannot be terminated before this period)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contract Term Duration',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _showContractTermPicker(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Iconsax.timer,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _getContractTermDisplayText(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: (_selectedContractDays > 0 ||
                                                  _selectedContractHours > 0 ||
                                                  _selectedContractMinutes > 0)
                                              ? Colors.grey[800]
                                              : Colors.grey[500],
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Iconsax.arrow_down_1,
                                      color: Colors.grey[600],
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_selectedContractDays == 0 &&
                                _selectedContractHours == 0 &&
                                _selectedContractMinutes == 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 4),
                                child: Text(
                                  'Select contract duration (when contract can be closed)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Budget Contract Details
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Iconsax.wallet_3,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Budget Contract Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[800],
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Define the terms and budget amount',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _titleController,
                        label: 'Contract Title',
                        hint: 'Enter a descriptive title',
                        prefixIcon:
                            const Icon(Iconsax.text, color: Colors.grey),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Enter contract description and conditions',
                        prefixIcon: const Icon(
                          Iconsax.document_text,
                          color: Colors.grey,
                        ),
                        minLines: 3,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _amountController,
                        label: 'Budget Amount (TZS)',
                        hint: 'Enter the total budget amount',
                        prefixIcon:
                            const Icon(Iconsax.money_send, color: Colors.grey),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid amount';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Amount must be greater than 0';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.green[700]!,
                        Colors.green[500]!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createBudgetContract,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Creating Contract...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Iconsax.wallet_3,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Create Budget Contract',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Footer Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your budget contract will be created. Funds can be added later.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContractTypeOption(
    String type,
    String description,
    IconData icon,
    ContractType contractType,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: isSelected ? 2 : 1,
            color: isSelected ? Colors.green : Colors.grey[300]!,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.green : Colors.grey[600],
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              type,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.green : Colors.grey[800],
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Colors.green.withOpacity(0.8)
                    : Colors.grey[600],
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getContractTermDisplayText() {
    if (_selectedContractDays == 0 &&
        _selectedContractHours == 0 &&
        _selectedContractMinutes == 0) {
      return 'Select contract duration';
    }

    List<String> parts = [];
    if (_selectedContractDays > 0) {
      parts.add(
          '${_selectedContractDays} ${_selectedContractDays == 1 ? 'day' : 'days'}');
    }
    if (_selectedContractHours > 0) {
      parts.add(
          '${_selectedContractHours} ${_selectedContractHours == 1 ? 'hour' : 'hours'}');
    }
    if (_selectedContractMinutes > 0) {
      parts.add(
          '${_selectedContractMinutes} ${_selectedContractMinutes == 1 ? 'minute' : 'minutes'}');
    }

    return parts.join(', ');
  }

  void _showContractTermPicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[300]!,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: CupertinoColors.destructiveRed,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Text(
                      'Contract Duration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Pickers
              Expanded(
                child: Row(
                  children: [
                    // Days Picker
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _selectedContractDays,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (int value) {
                          setState(() {
                            _selectedContractDays = value;
                          });
                        },
                        children: List<Widget>.generate(366, (int index) {
                          return Center(
                            child: Text(
                              '$index ${index == 1 ? 'day' : 'days'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }),
                      ),
                    ),
                    // Hours Picker
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _selectedContractHours,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (int value) {
                          setState(() {
                            _selectedContractHours = value;
                          });
                        },
                        children: List<Widget>.generate(24, (int index) {
                          return Center(
                            child: Text(
                              '$index ${index == 1 ? 'hour' : 'hours'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }),
                      ),
                    ),
                    // Minutes Picker
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _selectedContractMinutes,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (int value) {
                          setState(() {
                            _selectedContractMinutes = value;
                          });
                        },
                        children: List<Widget>.generate(60, (int index) {
                          return Center(
                            child: Text(
                              '$index ${index == 1 ? 'minute' : 'minutes'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
