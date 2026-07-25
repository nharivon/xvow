// App-wide constants. Business-rule numbers (XP values, default amounts)
// live here so they're never magic numbers scattered in feature code.

class AppConstants {
  AppConstants._();

  static const int maxActiveObjectives = 3;
  static const int objectiveDurationWeeks = 5;
  static const int maxPlannedVowsPerObjective = 5;
  static const int maxActiveWeeklyVows = 3;
  static const int successfulWeekXp = 20;
  static const int xpPerLevel = 60;
  static const int successfulWeekDisciplineDelta = 2;
  static const int failedWeekDisciplineDelta = -5;
  static const int failedWeekObjectiveHealthDelta = 10;
  static const int initialDiscipline = 100;
  static const int initialProjectHealth = 100;
  static const int weeklyValidationTarget = 3;
  static const int virtualDepositAmount = 2;
  static const int virtualPenaltyAmount = 1;
  static const int weekLockDays = 7;
}
