import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../providers/auth_provider.dart';
import '../../tasks/providers/task_provider.dart';
import 'package:project_plan/features/tasks/models/task_model.dart';
import '../../../core/theme/app_colors.dart';

// ── Custom Colors from M3 Mockup ─────────────
// ── Refined Colors (Neutral Slate/Gray) ─────────────
const _refinedProfileBgTop    = Color(0xFFDFE8ED); // Clean slate-blue for top half
const _refinedProfileIcon     = Color(0xFF475569); // Slate 600
const _refinedProfileText     = Color(0xFF1E293B); // Slate 900
const _refinedAvatarBorder    = Color(0xFF64748B); // Slate 500

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgTop = isDark ? const Color(0xFF1F2933) : _refinedProfileBgTop;
    final bgBottom = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardBg = isDark ? AppColors.cardDarkElevated : AppColors.cardLight;
    final statCardBg = isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC); // Neutral Slate 50
    final iconColor = isDark ? Colors.white70 : _refinedProfileIcon;
    final textColor = isDark ? Colors.white : _refinedProfileText;
    final avatarBorder = isDark ? AppColors.primary : _refinedAvatarBorder;

    return Scaffold(
      backgroundColor: bgBottom,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: bgTop,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Dashboard',
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w400,
            ),
          ),
          centerTitle: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: Icon(Icons.settings_outlined, color: textColor),
                onPressed: () => context.push('/home/settings'),
              ),
            ),
          ],
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) {
          final msg = e.toString();
          if (msg.contains('permission-denied') || msg.contains('PERMISSION_DENIED')) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(child: Text('Error: $msg'));
        },
        data:    (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.person_off_rounded, size: 64, color: iconColor.withValues(alpha: 0.5)),
                   const SizedBox(height: 16),
                   Text(
                     'Profile Not Initialized',
                     style: TextStyle(fontSize: 20, color: textColor, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 8),
                   const Text(
                     'Your account exists, but we couldn\'t find your profile data.',
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 24),
                   ElevatedButton.icon(
                     onPressed: () => ref.read(authNotifierProvider.notifier).initializeProfile(),
                     icon: const Icon(Icons.auto_fix_high_rounded),
                     label: const Text('Finalize Setup'),
                   ),
                   const SizedBox(height: 12),
                   TextButton.icon(
                     onPressed: () async {
                       await ref.read(authNotifierProvider.notifier).signOut();
                       if (context.mounted) context.go('/login');
                     },
                     icon: const Icon(Icons.logout_rounded),
                     label: const Text('Log Out'),
                   ),
                ],
              ),
            );
          }
          
          return Stack(
            children: [
              // ── Two-tone Background ──
              Column(
                children: [
                  Container(
                    height: 250,
                    color: bgTop,
                  ),
                  Expanded(
                    child: Container(color: bgBottom),
                  ),
                ],
              ),
              
              // ── Main Content ──
              ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 40),

                  // ── Avatar ────────────────────────────────────
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTap: () => _pickImage(context, ref),
                          child: Container(
                            padding: const EdgeInsets.all(4), // For the white border effect
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: isDark ? AppColors.cardDarkElevated : Colors.grey.shade300,
                              backgroundImage: user.photoURL.isNotEmpty
                                  ? (user.photoURL.startsWith('http') 
                                      ? NetworkImage(user.photoURL) 
                                      : FileImage(File(user.photoURL)) as ImageProvider)
                                  : null,
                              child: user.photoURL.isEmpty
                                  ? Text(
                                      user.displayName.isNotEmpty
                                          ? user.displayName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        // Small icon badge
                        GestureDetector(
                          onTap: () => _pickImage(context, ref),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: avatarBorder,
                              border: Border.all(color: cardBg, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Name ──────────────────────────────────────
                  Center(
                    child: Text(
                      user.displayName.isEmpty ? 'Demo User' : user.displayName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Stats Row (inside the white arch container) ──
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: const BorderRadius.all(Radius.circular(32)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                    child: ref.watch(allTasksProvider).when(
                      data: (tasks) {
                        final completedTasksCount = tasks.where((t) => t.status == TaskStatus.completed).length;
                        
                        // Fake on-time calculation for demonstration, you can map this to actual completion times vs due dates if tracked. 
                        // Right now assuming every completed task was "on time" if marked completed.
                        final onTimeRate = tasks.isEmpty ? 0 : (completedTasksCount / tasks.length * 100).round();

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatPill(
                              title: 'Tasks\nCompleted',
                              value: '$completedTasksCount',
                              backgroundColor: statCardBg,
                              textColor: textColor,
                            ),
                            _StatPill(
                              title: 'Current\nStreak',
                              value: '${user.streakCount}',
                              icon: Icons.local_fire_department_rounded,
                              backgroundColor: statCardBg,
                              textColor: textColor,
                            ),
                            _StatPill(
                              title: 'On-Time\nRate',
                              value: '$onTimeRate%', 
                              backgroundColor: statCardBg,
                              textColor: textColor,
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatPill(title: 'Tasks\nCompleted', value: '0', backgroundColor: statCardBg, textColor: textColor,),
                          _StatPill(title: 'Current\nStreak', value: '${user.streakCount}', icon: Icons.local_fire_department_rounded, backgroundColor: statCardBg, textColor: textColor,),
                          _StatPill(title: 'On-Time\nRate', value: '0%', backgroundColor: statCardBg, textColor: textColor,),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── List Options ─────────────────────────
                  _ProfileListTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    iconColor: iconColor,
                    textColor: textColor,
                    onTap: () => _showEditNameDialog(context, ref, user.displayName),
                  ),
                  const SizedBox(height: 12),
                  _ProfileListTile(
                    icon: Icons.settings_outlined,
                    title: 'Account Settings',
                    iconColor: iconColor,
                    textColor: textColor,
                    onTap: () => context.push('/home/settings'),
                  ),
                  const SizedBox(height: 12),
                  _ProfileListTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Feedback',
                    iconColor: iconColor,
                    textColor: textColor,
                    onTap: () async {
                      final Uri url = Uri.parse('mailto:support@example.com?subject=Pie App Feedback');
                      if (!await launchUrl(url)) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open email client'), behavior: SnackBarBehavior.floating));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _ProfileListTile(
                    icon: Icons.logout_rounded,
                    title: 'Log Out',
                    iconColor: iconColor,
                    textColor: textColor,
                    onTap: () async {
                      final confirmed = await _confirmSignOut(context);
                      if (confirmed && context.mounted) {
                        await ref.read(authNotifierProvider.notifier).signOut();
                        if (context.mounted) context.go('/login');
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      ref.read(authNotifierProvider.notifier).updateProfile(photoURL: image.path);
    }
  }

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter your name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(authNotifierProvider.notifier).updateProfile(displayName: controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmSignOut(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ── Sub-Widgets ────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.title,
    required this.value,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  final String title;
  final String value;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, // Fixed width for consistency
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor, // Light green-grey pill color
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 20, color: textColor),
              ],
            ],
          ),
          if (icon != null) // If it's the streak pill, add "Days"
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Days',
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  const _ProfileListTile({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
