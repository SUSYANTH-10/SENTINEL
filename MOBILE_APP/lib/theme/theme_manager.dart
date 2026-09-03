import 'package:flutter/material.dart';

class ThemeManager {
  ThemeManager._();
  static final ThemeManager instance = ThemeManager._();

  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  ThemeMode get themeMode => themeModeNotifier.value;

  void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  void toggleTheme(BuildContext context) {
    final Brightness currentBrightness =
        Theme.of(context).brightness;

    if (currentBrightness == Brightness.dark) {
      themeModeNotifier.value = ThemeMode.light;
    } else {
      themeModeNotifier.value = ThemeMode.dark;
    }
  }

  bool isDarkMode(BuildContext context) {
    if (themeModeNotifier.value == ThemeMode.dark) {
      return true;
    } else if (themeModeNotifier.value == ThemeMode.light) {
      return false;
    } else {
      return MediaQuery.platformBrightnessOf(context) ==
          Brightness.dark;
    }
  }
}

final themeManager = ThemeManager.instance;

class ThemeToggleButton extends StatelessWidget {
  final Color? color;

  const ThemeToggleButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeManager.themeModeNotifier,
      builder: (context, mode, child) {
        final bool isDark = themeManager.isDarkMode(context);

        return IconButton(
          tooltip: isDark
              ? 'Switch to Light Theme'
              : 'Switch to Dark Theme',
          icon: Icon(
            isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_outlined,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => themeManager.toggleTheme(context),
        );
      },
    );
  }
}
