import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/settings/providers/settings_provider.dart';

class ThemeToggleSwitch extends ConsumerWidget {
  const ThemeToggleSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Treat 'system' as dark if the OS is dark, light if OS is light
    final settings = ref.watch(settingsProvider);
    final mode = settings.themeMode;
    final isCurrentlyDark = mode == ThemeMode.dark || 
      (mode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return GestureDetector(
      onTap: () {
        ref.read(settingsProvider.notifier).updateThemeMode(isCurrentlyDark ? ThemeMode.light : ThemeMode.dark);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: isCurrentlyDark ? const Color(0xFF2E3547) : const Color(0xFFD4E3ED),
          border: Border.all(
            color: isCurrentlyDark ? Colors.white24 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Icons layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.wb_sunny_rounded,
                    color: isCurrentlyDark ? Colors.grey : const Color(0xFFEAA221),
                    size: 16,
                  ),
                  Icon(
                    Icons.nightlight_round_sharp,
                    color: isCurrentlyDark ? Colors.white : Colors.grey,
                    size: 16,
                  ),
                ],
              ),
            ),
            // The sliding indicator circle
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: isCurrentlyDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrentlyDark ? Colors.black : const Color(0xFFFACC15),
                    border: isCurrentlyDark ? Border.all(color: Colors.white, width: 2) : Border.all(color: const Color(0xFFEAA221), width: 2),
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
