import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_text_field.dart';
import '../services/contract_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../utils/custom_snackbar.dart';

class CreateContractScreen extends StatefulWidget {
  const CreateContractScreen({super.key});

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'Remitter';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rewardController = TextEditingController();
  final _secondParticipantController = TextEditingController();
  bool _isLoading = false;
  final _contractService = ContractService();
  final _userService = UserService();
  UserModel? _selectedSecondParticipant;
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
    _rewardController.dispose();
    _secondParticipantController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _createContract() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSecondParticipant == null) {
        CustomSnackBar.show(
          context: context,
          message: 'Please select a second participant',
          type: SnackBarType.error,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final user = Provider.of<UserProvider>(context, listen: false).user!;

        await _contractService.createContract(
          userId: user.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          reward: double.parse(_rewardController.text.trim()),
          role: _selectedRole,
          userFullName: user.fullName,
          userPhone: user.phone,
          secondParticipantId: _selectedSecondParticipant!.id,
          secondParticipantName: _selectedSecondParticipant!.fullName,
          secondParticipantPhone: _selectedSecondParticipant!.phone,
        );

        if (mounted) {
          CustomSnackBar.show(
            context: context,
            message: 'Contract created successfully',
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Create New Contract',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
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
                // Role Selection
                Text(
                  'Select your role',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(width: 0.5, color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildRoleOption(
                          'Remitter',
                          Iconsax.user,
                          _selectedRole == 'Remitter',
                          () {
                            setState(() {
                              _selectedRole = 'Remitter';
                              _selectedSecondParticipant = null;
                              _secondParticipantController.clear();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRoleOption(
                          'Beneficiary',
                          Iconsax.user_tick,
                          _selectedRole == 'Beneficiary',
                          () {
                            setState(() {
                              _selectedRole = 'Beneficiary';
                              _selectedSecondParticipant = null;
                              _secondParticipantController.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Second Participant Search
                Text(
                  '${_selectedRole == 'Remitter' ? 'Beneficiary' : 'Remitter'}\'s Phone Number',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _secondParticipantController,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  prefixIcon: const Icon(Iconsax.user, color: Colors.grey),
                  onChanged: (value) {
                    setState(() {
                      _selectedSecondParticipant = null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
                StreamBuilder<List<UserModel>>(
                  stream: _userService
                      .searchUsersByPhone(_secondParticipantController.text),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData ||
                        snapshot.data!.isEmpty ||
                        _selectedSecondParticipant != null) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final user = snapshot.data![index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  const Color(0xFF22C55E).withOpacity(0.1),
                              child: Text(
                                user.fullName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF22C55E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              user.fullName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              user.phone,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedSecondParticipant = user;
                                _secondParticipantController.text = user.phone;
                              });
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
                if (_selectedSecondParticipant != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              const Color(0xFF22C55E).withOpacity(0.5),
                          radius: 24,
                          child: Text(
                            _selectedSecondParticipant!.fullName[0]
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF22C55E),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedSecondParticipant!.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _selectedSecondParticipant!.phone,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _selectedSecondParticipant = null;
                              _secondParticipantController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                // Contract Details Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(width: 0.5, color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contract Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _titleController,
                        label: 'Contract Title',
                        hint: 'Enter contract title',
                        prefixIcon: const Icon(Icons.title_outlined,
                            color: Colors.grey),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _descriptionController,
                        label: 'Contract Conditions',
                        hint: 'Enter contract conditions',
                        prefixIcon: const Icon(Icons.description_outlined,
                            color: Colors.grey),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _rewardController,
                        label: 'Reward Amount',
                        hint: 'Enter amount',
                        prefixIcon: const Icon(Icons.attach_money_outlined,
                            color: Colors.grey),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createContract,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Contract',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(
    String role,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF22C55E).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: 0.5,
            color: isSelected ? const Color(0xFF22C55E) : Colors.grey[300]!,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF22C55E) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              role,
              style: TextStyle(
                color: isSelected ? const Color(0xFF22C55E) : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
