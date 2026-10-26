import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

/// Override this provider at app startup with the resolved [SharedPreferences].
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  );
});

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _prefsKey = 'kv_theme_mode';

  @override
  ThemeMode build() {
    final value = ref.read(sharedPreferencesProvider).getString(_prefsKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    await ref.read(sharedPreferencesProvider).setString(
      _prefsKey,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
    state = mode;
  }
}

abstract final class AppTheme {
  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.ink,
    onPrimary: Colors.white,
    primaryContainer: AppColors.sageTint,
    onPrimaryContainer: Color(0xFF1E3A2A),
    secondary: AppColors.sage,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE7F0EA),
    onSecondaryContainer: Color(0xFF22402F),
    tertiary: Color(0xFFB86B7C),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFF8E1E6),
    onTertiaryContainer: Color(0xFF4A1F2A),
    error: Color(0xFFC2413A),
    onError: Colors.white,
    errorContainer: Color(0xFFFBE3E0),
    onErrorContainer: Color(0xFF5C1612),
    surface: AppColors.lightCanvas,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.inkSoft,
    surfaceContainerLowest: AppColors.lightCard,
    surfaceContainerLow: Color(0xFFF9FAF8),
    surfaceContainer: Color(0xFFEEF1EC),
    surfaceContainerHigh: Color(0xFFE8EBE5),
    surfaceContainerHighest: Color(0xFFE2E6DF),
    outline: Color(0xFF8D968F),
    outlineVariant: Color(0xFFDDE2DA),
    inverseSurface: AppColors.ink,
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFFA9CDB5),
    shadow: Color(0xFF1B211D),
    scrim: Colors.black,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.mist,
    onPrimary: Color(0xFF1A1222),
    primaryContainer: Color(0xFF3B2D4E),
    onPrimaryContainer: Color(0xFFEBDDFF),
    secondary: AppColors.lilac,
    onSecondary: Color(0xFF2A1A40),
    secondaryContainer: Color(0xFF3A2B4F),
    onSecondaryContainer: Color(0xFFEADCFF),
    tertiary: AppColors.pink,
    onTertiary: Color(0xFF3B1530),
    tertiaryContainer: Color(0xFF4A2741),
    onTertiaryContainer: Color(0xFFFFD8EE),
    error: Color(0xFFFF8F84),
    onError: Color(0xFF3B0A06),
    errorContainer: Color(0xFF5A1E22),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: AppColors.darkCanvas,
    onSurface: AppColors.mist,
    onSurfaceVariant: AppColors.mistSoft,
    surfaceContainerLowest: Color(0xFF110C17),
    surfaceContainerLow: Color(0xFF1C1525),
    surfaceContainer: AppColors.darkCard,
    surfaceContainerHigh: Color(0xFF2A2136),
    surfaceContainerHighest: Color(0xFF33293F),
    outline: Color(0xFF85799A),
    outlineVariant: Color(0xFF3A3046),
    inverseSurface: AppColors.mist,
    onInverseSurface: Color(0xFF1A1222),
    inversePrimary: Color(0xFF6C4FA8),
    shadow: Colors.black,
    scrim: Colors.black,
  );

  static ThemeData get light => _base(_lightScheme);
  static ThemeData get dark => _base(_darkScheme);

  /// Background of cards and other raised surfaces.
  static Color cardColor(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark
      ? scheme.surfaceContainer
      : scheme.surfaceContainerLowest;

  static const _pill = StadiumBorder();

  static ThemeData _base(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final card = cardColor(scheme);
    final hairline = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : scheme.outlineVariant.withValues(alpha: 0.7);
    final text = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppColors.fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: hairline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: hairline),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.secondary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: _pill,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: const TextStyle(
            fontFamily: AppColors.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: _pill,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: AppColors.fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: _pill,
          foregroundColor: isDark ? AppColors.lilac : AppColors.sage,
          textStyle: const TextStyle(
            fontFamily: AppColors.fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.onSurface),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: hairline),
        backgroundColor: card,
        selectedColor: scheme.primary,
        showCheckmark: false,
        labelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            fontFamily: AppColors.fontFamily,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurface,
          ),
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: AppColors.fontFamily,
          fontWeight: FontWeight.w600,
          color: scheme.onPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          side: WidgetStatePropertyAll(BorderSide(color: hairline)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? scheme.primary : card,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurfaceVariant,
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: AppColors.fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(100),
        ),
        labelColor: scheme.onPrimary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: const TextStyle(
          fontFamily: AppColors.fontFamily,
          fontWeight: FontWeight.w600,
        ),
        splashBorderRadius: BorderRadius.circular(100),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        useIndicator: true,
        indicatorColor: scheme.primary,
        indicatorShape: const StadiumBorder(),
        selectedIconTheme: IconThemeData(color: scheme.onPrimary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: text.labelLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: text.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: text.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        highlightElevation: 4,
        shape: const StadiumBorder(),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(color: hairline, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? AppColors.lilac : AppColors.sage,
        linearTrackColor: scheme.surfaceContainerHigh,
        circularTrackColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: AppColors.fontFamily,
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: text.titleLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    TextStyle s(double size, FontWeight w, {double ls = 0, double? h}) =>
        TextStyle(
          fontFamily: AppColors.fontFamily,
          fontSize: size,
          fontWeight: w,
          letterSpacing: ls,
          height: h,
          color: scheme.onSurface,
        );
    return TextTheme(
      displayLarge: s(52, FontWeight.w300, ls: -1.5),
      displayMedium: s(42, FontWeight.w300, ls: -1.2),
      displaySmall: s(34, FontWeight.w300, ls: -0.8, h: 1.15),
      headlineLarge: s(30, FontWeight.w400, ls: -0.6, h: 1.15),
      headlineMedium: s(26, FontWeight.w500, ls: -0.5, h: 1.2),
      headlineSmall: s(22, FontWeight.w600, ls: -0.3, h: 1.25),
      titleLarge: s(19, FontWeight.w600, ls: -0.2),
      titleMedium: s(16, FontWeight.w600, ls: -0.1),
      titleSmall: s(14, FontWeight.w600),
      bodyLarge: s(16, FontWeight.w400, h: 1.5),
      bodyMedium: s(14, FontWeight.w400, h: 1.45),
      bodySmall: s(
        12.5,
        FontWeight.w400,
        h: 1.4,
      ).copyWith(color: scheme.onSurfaceVariant),
      labelLarge: s(14, FontWeight.w600),
      labelMedium: s(12, FontWeight.w600),
      labelSmall: s(11, FontWeight.w600, ls: 0.2),
    );
  }
}
