import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_text_field.dart';
import '../services/contract_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class CreateContractScreen extends StatefulWidget {
  const CreateContractScreen({super.key});

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'Benefactor';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rewardController = TextEditingController();
  final _secondParticipantController = TextEditingController();
  bool _isLoading = false;
  final _contractService = ContractService();
  final _userService = UserService();
  UserModel? _selectedSecondParticipant;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rewardController.dispose();
    _secondParticipantController.dispose();
    super.dispose();
  }

  Future<void> _createContract() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSecondParticipant == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a second participant'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final user = userProvider.user;

        if (user == null) {
          throw Exception('User not found');
        }

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contract created successfully'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Contract'),
        backgroundColor: const Color(0xFF22C55E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role Selection
              Text(
                'Your Role',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    items: ['Benefactor', 'Beneficiary']
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                          _selectedSecondParticipant = null;
                          _secondParticipantController.clear();
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 15),
              // Second Participant Search
              Text(
                '${_selectedRole == 'Benefactor' ? 'Beneficiary' : 'Benefactor'}\'s Phone Number',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
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
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
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
                          title: Text(user.fullName),
                          subtitle: Text(user.phone),
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            const Color(0xFF22C55E).withOpacity(0.2),
                        child: Text(
                          _selectedSecondParticipant!.fullName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedSecondParticipant!.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _selectedSecondParticipant!.phone,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
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

              const SizedBox(height: 15),
              CustomTextField(
                controller: _titleController,
                label: 'Contract Title',
                hint: 'Enter contract title',
                prefixIcon:
                    const Icon(Icons.title_outlined, color: Colors.grey),
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
                label: 'Description',
                hint: 'Enter contract description',
                prefixIcon:
                    const Icon(Icons.description_outlined, color: Colors.grey),
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
                prefixIcon:
                    const Icon(Icons.attach_money_outlined, color: Colors.grey),
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createContract,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Contract',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
}
