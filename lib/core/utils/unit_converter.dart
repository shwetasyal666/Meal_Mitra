class UnitConverter {
  UnitConverter._();

  static const double cmPerFoot = 30.48;
  static const double cmPerInch = 2.54;
  static const double lbsPerKg = 2.20462;

  // Height Helpers
  static int ftInToCm(int feet, int inches) {
    return ((feet * cmPerFoot) + (inches * cmPerInch)).round();
  }

  static (int feet, int inches) cmToFtIn(int cm) {
    int totalInches = (cm / cmPerInch).round();
    int feet = totalInches ~/ 12;
    int inches = totalInches % 12;
    return (feet, inches);
  }

  static String formatHeight(int cm, bool useMetric) {
    if (useMetric) {
      return '$cm cm';
    } else {
      final ftIn = cmToFtIn(cm);
      return '${ftIn.$1}\'${ftIn.$2}"';
    }
  }

  // Weight Helpers
  static double lbsToKg(double lbs) {
    return lbs / lbsPerKg;
  }

  static double kgToLbs(double kg) {
    return kg * lbsPerKg;
  }

  static String formatWeight(int kg, bool useMetric) {
    if (useMetric) {
      return '$kg kg';
    } else {
      return '${kgToLbs(kg.toDouble()).round()} lbs';
    }
  }
}
