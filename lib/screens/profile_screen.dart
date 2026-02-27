import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import 'terms_conditions_screen.dart';
import 'change_password_screen.dart';
import 'notification_settings_screen.dart';
import 'delete_account_webview.dart';
import 'privacy_policy_webview.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showHelpCenterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'For support, inquiries, or complaints, reach us at:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            _buildContactOption(
              context,
              'Email Support',
              'rfroulis@gmail.com',
              Iconsax.message,
              () async {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'rfroulis@gmail.com',
                  queryParameters: {
                    'subject': 'Escrow App Support',
                  },
                );
                try {
                  await launchUrlString(emailLaunchUri.toString());
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not launch email client'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            _buildContactOption(
              context,
              'WhatsApp Support',
              '+255 620 719 589',
              Iconsax.message_text_1,
              () async {
                try {
                  await launchUrlString(
                    'https://wa.me/255620719589?text=Hello, I need help with the Escrow App',
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not launch WhatsApp'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: 0.5,
            color: Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF22C55E),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    Widget userAvatar = RandomAvatar(userProvider.user?.fullName ?? 'User',
        trBackground: true, height: 100, width: 100);
    Widget smallAvatar = RandomAvatar(userProvider.user?.fullName ?? 'User',
        trBackground: true, height: 32, width: 32);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.green,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final isCollapsed = constraints.biggest.height <= kToolbarHeight + MediaQuery.of(context).padding.top;
                return FlexibleSpaceBar(
                  titlePadding: isCollapsed ? const EdgeInsets.only(left: 16, bottom: 16) : EdgeInsets.zero,
                  title: isCollapsed
                      ? Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 1.5),
                                shape: BoxShape.circle,
                              ),
                              child: smallAvatar,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    userProvider.user?.fullName ?? 'User',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    userProvider.user?.phone ?? 'Not set',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.green, Colors.green],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 3),
                              shape: BoxShape.circle,
                            ),
                            child: userAvatar,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            userProvider.user?.fullName ?? 'User',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            userProvider.user?.phone ?? 'Not set',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            actions: [
              IconButton.outlined(
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  side: const BorderSide(
                    color: Colors.transparent,
                  ),
                ),
                onPressed: () async {
                  try {
                    final authService = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    final userProvider = Provider.of<UserProvider>(
                      context,
                      listen: false,
                    );

                    // Clear user data from provider
                    userProvider.clearUser();

                    // Sign out from auth service
                    await authService.signOut();

                    if (context.mounted) {
                      // Navigate to login screen
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/',
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error signing out: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(
                  Iconsax.logout,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          // Profile Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    context,
                    'Account Information',
                    [
                      _buildProfileItem(
                        context,
                        'Full Name',
                        userProvider.user?.fullName ?? 'Not set',
                        Iconsax.user,
                      ),
                      _buildProfileItem(
                        context,
                        'Email',
                        userProvider.user?.email ?? 'Not set',
                        Iconsax.message,
                      ),
                      _buildProfileItem(
                        context,
                        'Phone',
                        userProvider.user?.phone ?? 'Not set',
                        Iconsax.call,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    'Settings',
                    [
                      _buildProfileItem(
                        context,
                        'Change Password',
                        'Update your password',
                        Iconsax.lock,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),
                      _buildProfileItem(
                        context,
                        'Notifications',
                        'Manage notification preferences',
                        Iconsax.notification,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildAdvancedExpansion(context),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    'Support',
                    [
                      _buildProfileItem(
                        context,
                        'Help Center',
                        'Get help and support',
                        Iconsax.message_question,
                        onTap: () => _showHelpCenterBottomSheet(context),
                      ),
                      _buildProfileItem(
                        context,
                        'Terms & Conditions',
                        'Read our terms and conditions',
                        Iconsax.document_text,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TermsConditionsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildProfileItem(
                        context,
                        'Privacy Policy',
                        'Read our privacy policy',
                        Iconsax.shield_tick,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PrivacyPolicyWebView(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final authService = Provider.of<AuthService>(
                            context,
                            listen: false,
                          );
                          final userProvider = Provider.of<UserProvider>(
                            context,
                            listen: false,
                          );

                          // Clear user data from provider
                          userProvider.clearUser();

                          // Sign out from auth service
                          await authService.signOut();

                          if (context.mounted) {
                            // Navigate to login screen
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/',
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error signing out: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Iconsax.logout,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedExpansion(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        childrenPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Iconsax.setting_2,
            color: Colors.green,
            size: 20,
          ),
        ),
        title: const Text(
          'Advanced',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'More account options',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        iconColor: Colors.grey,
        collapsedIconColor: Colors.grey,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.red.withOpacity(0.25), width: 1),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.trash, color: Colors.red, size: 20),
              ),
              title: const Text(
                'Delete Account',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              subtitle: Text(
                'Permanently removes all your data',
                style:
                    TextStyle(color: Colors.red.withOpacity(0.7), fontSize: 13),
              ),
              trailing: const Icon(Iconsax.arrow_right_3,
                  size: 20, color: Colors.red),
              onTap: () => _confirmDeleteAccount(context),
            ),
          ),
        ],
      ),
    );
  }


  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.trash, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: const Text(
          'This action is irreversible. All your contracts, transactions, and personal data will be permanently deleted.\n\nAre you absolutely sure you want to continue?',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeleteAccountWebView(),
                ),
              );
            },
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.green,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: onTap != null
            ? const Icon(
                Iconsax.arrow_right_3,
                size: 20,
                color: Colors.grey,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
