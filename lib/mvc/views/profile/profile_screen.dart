import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/glass_card.dart';
import '../../../constants/app_constants.dart';
import '../../models/app_theme.dart';
import '../../controllers/auth_service.dart';
import '../../controllers/supabase.dart';
import '../../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      await AuthService().loadUserFromStorage();
      setState(() {
        _user = AuthService.currentUser;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _editProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _EditProfileDialog(user: _user),
    );
  }

  void _changePassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ChangePasswordDialog(),
    );
  }

  void _notificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _NotificationSettingsDialog(),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grad = isDark ? AppTheme.darkGradientColors : AppTheme.lightGradientColors;
    final cardBg = isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentRoute: '/profile'),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [grad[0], grad[1], cs.surface],
            stops: const [0.0, 0.55, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Profile Header
                _ProfileHeader(
                  user: _user,
                  cardBg: cardBg,
                  cs: cs,
                  grad: grad,
                ),
                
                const SizedBox(height: 24),
                
                // Stats Cards
                _StatsSection(
                  cardBg: cardBg,
                  cs: cs,
                ),
                
                const SizedBox(height: 24),
                
                // Profile Options
                _ProfileOptions(
                  cardBg: cardBg,
                  cs: cs,
                  onEditProfile: _editProfile,
                  onChangePassword: _changePassword,
                  onNotificationSettings: _notificationSettings,
                ),
                
                const SizedBox(height: 24),
                
                // Settings Section
                _SettingsSection(
                  cardBg: cardBg,
                  cs: cs,
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User? user;
  final Color cardBg;
  final ColorScheme cs;
  final List<Color> grad;

  const _ProfileHeader({
    this.user,
    required this.cardBg,
    required this.cs,
    required this.grad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        key: const ValueKey('profile_header'),
        color: cardBg,
        child: Column(
          children: [
            // Avatar with gradient background
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: grad,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: grad[0].withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  AppConstants.brandName[0],
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // User Info
            Text(
              user?.fullName ?? user?.username ?? '$AppConstants.brandName User',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            
            const SizedBox(height: 4),
            
            Text(
              user?.email ?? 'design@$AppConstants.brandName.app',
              style: TextStyle(
                fontSize: 16,
                color: cs.onSurface.withValues(alpha: 0.8),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (user?.isActive ?? true) ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (user?.isActive ?? true) ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: (user?.isActive ?? true) ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (user?.isActive ?? true) ? 'Aktif' : 'Pasif',
                        style: TextStyle(
                          color: (user?.isActive ?? true) ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user?.isVerified == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 12,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Doğrulanmış',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
}

class _StatsSection extends StatelessWidget {
  final Color cardBg;
  final ColorScheme cs;

  const _StatsSection({
    required this.cardBg,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Günler',
              value: '127',
              icon: Icons.calendar_today,
              color: Colors.blue,
              cardBg: cardBg,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: 'Saatler',
              value: '1,240',
              icon: Icons.access_time,
              color: Colors.orange,
              cardBg: cardBg,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: 'Seanslar',
              value: '89',
              icon: Icons.play_circle,
              color: Colors.purple,
              cardBg: cardBg,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color cardBg;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      key: ValueKey('stat_card_$title'),
      color: cardBg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOptions extends StatelessWidget {
  final Color cardBg;
  final ColorScheme cs;
  final Function(BuildContext) onEditProfile;
  final Function(BuildContext) onChangePassword;
  final Function(BuildContext) onNotificationSettings;

  const _ProfileOptions({
    required this.cardBg,
    required this.cs,
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onNotificationSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        key: const ValueKey('profile_options'),
        color: cardBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profil Seçenekleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _ProfileOptionTile(
              icon: Icons.edit,
              title: 'Profili Düzenle',
              subtitle: 'Kişisel bilgilerini güncelle',
              onTap: () => onEditProfile(context),
            ),
            _ProfileOptionTile(
              icon: Icons.security,
              title: 'Güvenlik',
              subtitle: 'Şifre ve güvenlik ayarları',
              onTap: () => onChangePassword(context),
            ),
            _ProfileOptionTile(
              icon: Icons.notifications,
              title: 'Bildirimler',
              subtitle: 'Bildirim tercihlerini yönet',
              onTap: () => onNotificationSettings(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final Color cardBg;
  final ColorScheme cs;

  const _SettingsSection({
    required this.cardBg,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        key: const ValueKey('settings_section'),
        color: cardBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ayarlar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _SettingsTile(
              icon: Icons.dark_mode,
              title: 'Tema',
              subtitle: 'Koyu mod',
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: Colors.blue,
              ),
            ),
            _SettingsTile(
              icon: Icons.language,
              title: 'Dil',
              subtitle: 'Türkçe',
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.5),
                size: 16,
              ),
            ),
            _SettingsTile(
              icon: Icons.help,
              title: 'Yardım',
              subtitle: 'Destek ve SSS',
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.5),
                size: 16,
              ),
            ),
            _SettingsTile(
              icon: Icons.info,
              title: 'Hakkında',
              subtitle: 'Uygulama bilgileri',
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.5),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final User? user;

  const _EditProfileDialog({this.user});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user?.fullName ?? '';
    _emailController.text = widget.user?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update user profile in Supabase
      final response = await SupabaseService().client
          .from('users')
          .update({
            'full_name': _nameController.text,
            'email': _emailController.text,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.user?.id ?? '')
          .select();

      // Convert PostgrestList to List<Map<String, dynamic>>
      final List<Map<String, dynamic>> responseList = List<Map<String, dynamic>>.from(response);

      if (responseList.isNotEmpty) {
        // Update local user data
        await AuthService().loadUserFromStorage();
        
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateProfile,
          child: _isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Update'),
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    if (_newPasswordController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 4 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verify current password
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User not found');
      }

      // Check current password
      final currentPasswordHash = AuthService().hashPassword(_currentPasswordController.text);
      if (currentPasswordHash != user.passwordHash) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current password is incorrect')),
        );
        return;
      }

      // Update password in Supabase
      final newPasswordHash = AuthService().hashPassword(_newPasswordController.text);
      await SupabaseService().client
          .from('users')
          .update({
            'password_hash': newPasswordHash,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing password: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _currentPasswordController,
            obscureText: _obscureCurrent,
            decoration: InputDecoration(
              labelText: 'Current Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureCurrent ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: 'New Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          child: _isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Change'),
        ),
      ],
    );
  }
}

class _NotificationSettingsDialog extends StatefulWidget {
  @override
  State<_NotificationSettingsDialog> createState() => _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState extends State<_NotificationSettingsDialog> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = AuthService.currentUser;
      if (user != null) {
        // Load notification settings from Supabase
        final response = await SupabaseService().client
            .from('users')
            .select('notification_settings')
            .eq('id', user.id);

        // Convert PostgrestList to List<Map<String, dynamic>>
        final List<Map<String, dynamic>> responseList = List<Map<String, dynamic>>.from(response);

        if (responseList.isNotEmpty && responseList.first['notification_settings'] != null) {
          final settings = responseList.first['notification_settings'] as Map<String, dynamic>;
          setState(() {
            _pushNotifications = settings['push'] ?? true;
            _emailNotifications = settings['email'] ?? true;
          });
        }
      }
    } catch (e) {
      // Use default settings
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      final user = AuthService.currentUser;
      if (user != null) {
        await SupabaseService().client
            .from('users')
            .update({
              'notification_settings': {
                'push': _pushNotifications,
                'email': _emailNotifications,
              },
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification settings saved')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notification Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive push notifications'),
            value: _pushNotifications,
            onChanged: (value) => setState(() => _pushNotifications = value),
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive email notifications'),
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSettings,
          child: _isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save'),
        ),
      ],
    );
  }
}
