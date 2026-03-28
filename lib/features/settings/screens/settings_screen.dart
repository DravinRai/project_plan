import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';

// ── Custom Colors from M3 Mockup ─────────────
// ── Refined Colors (Neutral Slate/Gray) ─────────────
const _refinedSettingsBgList    = Color(0xFFF1F5F9); // Neutral slate light
const _refinedSettingsBgHeader  = Color(0xFFE2E8F0); // Slightly darker slate for header
const _refinedSettingsCard      = Color(0xFFFFFFFF); // White cards
const _refinedIconColor         = Color(0xFF475569); // Slate 600
const _refinedListTextColor     = Color(0xFF1E293B); // Slate 900
const _refinedDividerColor      = Color(0xFFCBD5E1); // Slate 300

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Helpers for formatting ThemeMode and Language strings
  String _themeModeString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  String _languageString(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgList = isDark ? AppColors.surfaceDark : _refinedSettingsBgList;
    final bgHeader = isDark ? AppColors.cardDarkElevated : _refinedSettingsBgHeader;
    final cardBg = isDark ? AppColors.cardDarkElevated : _refinedSettingsCard;
    final iconColor = isDark ? Colors.white70 : _refinedIconColor;
    final textColor = isDark ? Colors.white : _refinedListTextColor;
    final dividerColor = isDark ? AppColors.dividerDark : _refinedDividerColor;

    return Scaffold(
      backgroundColor: bgList,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: bgHeader,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Settings',
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w400,
            ),
          ),
          centerTitle: false,
        ),
      ),
      body: Stack(
        children: [
          // Background extension for header overlap
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 20, // Extends the header color slightly down
            child: Container(
              color: bgHeader,
            ),
          ),
          
          // Main content with rounded top corners
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: bgList,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                children: [
                  // ── General Section ──
                  _SectionHeader(title: 'General', textColor: textColor),
                  const SizedBox(height: 12),
                  
                  // Notifications Tile
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: SwitchListTile(
                      value: settings.notificationsEnabled,
                      onChanged: (val) {
                        ref.read(settingsProvider.notifier).toggleNotifications(val);
                      },
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF3B6856), // Dark green track
                      inactiveThumbColor: iconColor, // The thumb itself
                      inactiveTrackColor: dividerColor.withValues(alpha: 0.5), // Visible track instead of transparent
                      secondary: Icon(Icons.notifications_none_rounded, color: iconColor),
                      title: Text('Notifications', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Theme & Language Tiles (Grouped)
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          leading: Icon(Icons.palette_outlined, color: iconColor),
                          title: Text('Theme', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                          subtitle: Text(_themeModeString(settings.themeMode), style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13)),
                          onTap: () async {
                            final mode = await showDialog<ThemeMode>(
                              context: context,
                              builder: (context) => SimpleDialog(
                                title: const Text('Select Theme'),
                                children: ThemeMode.values.map((m) {
                                  return RadioListTile<ThemeMode>(
                                    title: Text(_themeModeString(m)),
                                    value: m,
                                    groupValue: settings.themeMode, // ignore: deprecated_member_use
                                    onChanged: (val) => Navigator.pop(context, val), // ignore: deprecated_member_use
                                  );
                                }).toList(),
                              ),
                            );
                            if (mode != null) {
                              ref.read(settingsProvider.notifier).updateThemeMode(mode);
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(height: 1, thickness: 1, color: dividerColor.withValues(alpha: 0.5)),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          leading: Icon(Icons.language_rounded, color: iconColor),
                          title: Text('Language', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                          subtitle: Text(_languageString(settings.languageCode), style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13)),
                          onTap: () async {
                            final code = await showDialog<String>(
                              context: context,
                              builder: (context) => SimpleDialog(
                                title: const Text('Select Language'),
                                children: ['en', 'es', 'fr'].map((c) {
                                  return RadioListTile<String>(
                                    title: Text(_languageString(c)),
                                    value: c,
                                    groupValue: settings.languageCode, // ignore: deprecated_member_use
                                    onChanged: (val) => Navigator.pop(context, val), // ignore: deprecated_member_use
                                  );
                                }).toList(),
                              ),
                            );
                            if (code != null) {
                              ref.read(settingsProvider.notifier).updateLanguage(code);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // ── Data & Privacy Section ──
                  _SectionHeader(title: 'Data & Privacy', textColor: textColor),
                  const SizedBox(height: 12),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          leading: Icon(Icons.upload_rounded, color: iconColor),
                          title: Text('Export Data', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                          onTap: () async {
                            // Generating a simple PDF document with user data report
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating Export Data...'), behavior: SnackBarBehavior.floating));
                            
                            final pdf = pw.Document();
                            pdf.addPage(
                              pw.Page(
                                pageFormat: PdfPageFormat.a4,
                                build: (pw.Context context) {
                                  return pw.Center(
                                    child: pw.Column(
                                      mainAxisAlignment: pw.MainAxisAlignment.center,
                                      children: [
                                        pw.Text('Pie - User Data Export', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                                        pw.SizedBox(height: 20),
                                        pw.Text('Export Date: ${DateTime.now().toString()}'),
                                        pw.SizedBox(height: 40),
                                        pw.Text('This is a summary of your scheduled tasks, routines, and app preferences.', textAlign: pw.TextAlign.center),
                                        // A real app would read from repositories and add the list here
                                      ]
                                    ),
                                  );
                                },
                              ),
                            );

                            await Printing.sharePdf(bytes: await pdf.save(), filename: 'pie_export.pdf');
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(height: 1, thickness: 1, color: dividerColor.withValues(alpha: 0.5)),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          leading: Icon(Icons.shield_outlined, color: iconColor),
                          title: Text('Privacy Policy', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                          onTap: () => context.pushNamed(AppRoute.privacyPolicy.name),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // ── About Section ──
                  _SectionHeader(title: 'About', textColor: textColor),
                  const SizedBox(height: 12),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          leading: Icon(Icons.help_outline_rounded, color: iconColor),
                          title: Text('Help & Feedback', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                          onTap: () => context.pushNamed(AppRoute.feedback.name),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(height: 1, thickness: 1, color: dividerColor.withValues(alpha: 0.5)),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          leading: Icon(Icons.info_outline_rounded, color: iconColor),
                          title: Text('Version 2.1.0', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.textColor});
  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
