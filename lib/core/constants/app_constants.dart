import 'package:flutter/material.dart';

// ── API ──
const String API_URL = 'https://kewere-aissa-smart.onrender.com';
const String WEATHER_KEY = 'cea65cf01b5c5db78e93a83d09cbf66c';

// ── COULEURS PRINCIPALES ──
const Color kBlue = Color(0xFF1B3A6B);
const Color kBlueLight = Color(0xFF2563EB);
const Color kGreen = Color(0xFF16A34A);
const Color kOrange = Color(0xFFEA580C);
const Color kRed = Color(0xFFDC2626);
const Color kPurple = Color(0xFF7C3AED);
const Color kYellow = Color(0xFFF59E0B);
const Color kTeal = Color(0xFF0891B2);
const Color kPink = Color(0xFFEC4899);
const Color kIndigo = Color(0xFF4F46E5);

// ── COULEURS UI ──
const Color kBg = Color(0xFFF1F5F9);
const Color kCard = Colors.white;
const Color kDark = Color(0xFF0F172A);
const Color kDarkBlue = Color(0xFF1E3A5F);
const Color kGrey = Color(0xFF6B7280);
const Color kLightGrey = Color(0xFFE5E7EB);

// ── GRADIENTS ──
const LinearGradient kGradientDark = LinearGradient(
  colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kGradientGreen = LinearGradient(
  colors: [Color(0xFF16A34A), Color(0xFF059669)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kGradientBlue = LinearGradient(
  colors: [Color(0xFF1B3A6B), Color(0xFF2563EB)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kGradientIA = LinearGradient(
  colors: [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF4C1D95)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ── BORDURES ARRONDIES ──
const double kRadius = 12.0;
const double kRadiusLarge = 16.0;
const double kRadiusXL = 24.0;

const BorderRadius kBorderRadius =
BorderRadius.all(Radius.circular(kRadius));
const BorderRadius kBorderRadiusLarge =
BorderRadius.all(Radius.circular(kRadiusLarge));
const BorderRadius kBorderRadiusXL =
BorderRadius.all(Radius.circular(kRadiusXL));

// ── OMBRES ──
List<BoxShadow> kShadowSm = [
  BoxShadow(color: Colors.black.withOpacity(0.04),
      blurRadius: 6, offset: const Offset(0, 2))
];

List<BoxShadow> kShadowMd = [
  BoxShadow(color: Colors.black.withOpacity(0.06),
      blurRadius: 10, offset: const Offset(0, 3))
];

List<BoxShadow> kShadowLg = [
  BoxShadow(color: Colors.black.withOpacity(0.1),
      blurRadius: 20, offset: const Offset(0, 6))
];

// ── ESPACEMENTS ──
const double kPadding = 16.0;
const double kPaddingSm = 12.0;
const double kPaddingLg = 24.0;

// ── STYLES DE TEXTE ──
const TextStyle kTitle = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w900,
    color: Color(0xFF1E293B));

const TextStyle kSubtitle = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: Color(0xFF1E293B));

const TextStyle kBody = TextStyle(
    fontSize: 13, color: Color(0xFF1E293B));

const TextStyle kCaption = TextStyle(
    fontSize: 11, color: Colors.grey);

const TextStyle kTitleWhite = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w900,
    color: Colors.white);

// ── THÈME APP ──
ThemeData kTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kBlue,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: kBg,
  appBarTheme: const AppBarTheme(
    backgroundColor: kDark,
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 16,
        fontWeight: FontWeight.w800),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      textStyle: const TextStyle(
          fontWeight: FontWeight.w700, fontSize: 14),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kBlue,
      side: const BorderSide(color: kBlue),
      shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
        borderRadius: kBorderRadius,
        borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(
        borderRadius: kBorderRadius,
        borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: const OutlineInputBorder(
        borderRadius: kBorderRadius,
        borderSide: BorderSide(color: kBlue, width: 2)),
    contentPadding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 12),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
    margin: const EdgeInsets.only(bottom: 10),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: kBlue.withOpacity(0.08),
    labelStyle: const TextStyle(color: kBlue, fontSize: 11),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    shape: const StadiumBorder(),
  ),
  dividerTheme: DividerThemeData(
    color: Colors.grey.shade200,
    thickness: 1,
    space: 16,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: kBlue,
    foregroundColor: Colors.white,
    elevation: 4,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: kBlue,
    unselectedItemColor: Colors.grey.shade400,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
    backgroundColor: kDark,
    contentTextStyle: const TextStyle(
        color: Colors.white, fontWeight: FontWeight.w600),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: kBlue,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) =>
    states.contains(WidgetState.selected) ? kBlue : Colors.grey),
    trackColor: WidgetStateProperty.resolveWith((states) =>
    states.contains(WidgetState.selected)
        ? kBlue.withOpacity(0.3)
        : Colors.grey.withOpacity(0.3)),
  ),
);

// ── FINANCE PARAMS ──
class FinanceParams {
  static double prixSacAliment = 17600;
  static double prixVentePoulet = 2500;
  static double prixPoussin = 645;
  static double salairesMois = 445000;
  static double loyerMois = 200000;
  static double coutMedicalParPoussin = 115;
}

// ── HELPERS ──
String formatFcfa(double v) {
  final abs = v.abs();
  String formatted;
  if (abs >= 1000000) {
    formatted = '${(abs / 1000000).toStringAsFixed(1)}M';
  } else if (abs >= 1000) {
    formatted = '${(abs / 1000).toStringAsFixed(0)}K';
  } else {
    formatted = abs.toStringAsFixed(0);
  }
  return '${v < 0 ? '-' : ''}$formatted FCFA';
}

String formatFcfaFull(double v) =>
    '${v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]} ')} FCFA';

String formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

String formatDateHeure(DateTime d) =>
    '${d.day}/${d.month}/${d.year} à '
        '${d.hour}:${d.minute.toString().padLeft(2, '0')}';

// ── CONSTANTES AVICULTURE ──
const double kTempIdealeBas = 25.0;
const double kTempIdealeHaut = 32.0;
const double kTempCritique = 35.0;
const double kHumiditeIdealeBas = 50.0;
const double kHumiditeIdealeHaut = 70.0;
const double kHumiditeCritique = 80.0;
const double kTauxMortaliteAcceptable = 3.0;
const double kTauxMortaliteEleve = 5.0;
const double kTauxMortaliteCritique = 10.0;
const int kAgePouletOptimal = 42;
const int kDureeCycleStandard = 45;