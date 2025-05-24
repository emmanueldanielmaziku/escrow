import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/contract_service.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/glassmorphism_card.dart';

class CreateContractScreen extends StatefulWidget {
  const CreateContractScreen({super.key});

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _inviteePhoneController = TextEditingController();
  bool _acceptTerms = false;
  bool _isLoading = false;
  final _contractService = ContractService();
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _inviteePhoneController.dispose();
    super.dispose();
  }

  Future<String?> _getUserIdByPhone(String phone) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  Future<void> _createContract() async {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      setState(() {
        _isLoading = true;
      });

      try {
        final currentUser = _authService.getCurrentUserId();
        if (currentUser == null) {
          throw Exception('Please sign in to create a contract');
        }

        // Validate phone number format
        final phoneNumber = _inviteePhoneController.text.trim();
        if (!_isValidPhoneNumber(phoneNumber)) {
          throw Exception('Please enter a valid phone number');
        }

        // Get invitee's user ID from phone number
        final inviteeId = await _getUserIdByPhone(phoneNumber);
        if (inviteeId == null) {
          throw Exception(
              'Recipient not found. Please make sure they have registered with this phone number.');
        }

        if (inviteeId == currentUser) {
          throw Exception('You cannot create a contract with yourself');
        }

        // Create contract in Firebase
        final contractId = await _contractService.createContract(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          creatorId: currentUser,
          inviteeId: inviteeId,
        );

        // Generate WhatsApp message
        final inviteMessage = AppConstants.generateInviteMessage(
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          contractId: contractId,
        );

        // Share via WhatsApp
        await Share.share(
          inviteMessage,
          subject: 'Contract Invitation',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Contract created and invitation sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } on FirebaseException catch (e) {
        String errorMessage = 'Failed to create contract';
        if (e.code == 'permission-denied') {
          errorMessage =
              'You don\'t have permission to create contracts. Please contact support.';
        } else if (e.code == 'unavailable') {
          errorMessage =
              'Network error. Please check your connection and try again.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isValidPhoneNumber(String phone) {
    // Basic phone number validation for Tanzania
    // Format: +255 or 0 followed by 9 digits
    final phoneRegex = RegExp(r'^(\+255|0)[0-9]{9}$');
    return phoneRegex.hasMatch(phone);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Contract'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            GlassmorphismCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          child: Icon(
                            Iconsax.document,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Contract',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Create a new escrow agreement',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Iconsax.wallet_money,
                          size: 20,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your Balance: TSh ${user?.balance.toStringAsFixed(2) ?? "0.00"}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Contract Form
            GlassmorphismCard(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _titleController,
                        label: 'Contract Title',
                        hint: 'Enter a clear title for your contract',
                        prefixIcon: const Icon(Iconsax.document_text),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a contract title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint:
                            'Describe the terms and conditions of the contract',
                        prefixIcon: const Icon(Iconsax.document_text_1),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a contract description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _amountController,
                        label: 'Amount (TSh)',
                        hint: 'Enter the contract amount',
                        prefixIcon: const Icon(Iconsax.money),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a contract amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid amount';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Amount must be greater than zero';
                          }
                          if (user != null &&
                              double.parse(value) > user.balance) {
                            return 'Amount exceeds your wallet balance';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _inviteePhoneController,
                        label: 'Invitee Phone Number',
                        hint: 'Enter the recipient\'s phone number',
                        prefixIcon: const Icon(Iconsax.call),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter invitee phone number';
                          }
                          // Add phone number validation if needed
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptTerms = value ?? false;
                              });
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _acceptTerms = !_acceptTerms;
                                });
                              },
                              child: const Text(
                                'I accept the Terms & Conditions and confirm that I have sufficient funds in my wallet',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _createContract,
                          icon: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Iconsax.send_1),
                          label: Text(_isLoading
                              ? 'Creating...'
                              : 'Create & Send Invitation'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
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
