import 'dart:convert';

import '../constants/app_constants.dart';

String _dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

class PlannedVow {
  const PlannedVow({
    required this.id,
    required this.title,
    required this.weekIndex,
  });

  final String id;
  final String title;
  final int weekIndex;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'weekIndex': weekIndex,
  };

  factory PlannedVow.fromJson(Map<String, dynamic> json) {
    return PlannedVow(
      id: json['id'] as String,
      title: json['title'] as String,
      weekIndex: (json['weekIndex'] as num).toInt(),
    );
  }
}

class Objective {
  const Objective({
    required this.id,
    required this.title,
    required this.description,
    required this.motivation,
    required this.createdAt,
    required this.plannedVows,
    required this.completedWeeks,
    required this.failedWeeks,
    required this.health,
    required this.isCompleted,
  });

  final String id;
  final String title;
  final String description;
  final String motivation;
  final DateTime createdAt;
  final List<PlannedVow> plannedVows;
  final int completedWeeks;
  final int failedWeeks;
  final int health;
  final bool isCompleted;

  int get totalWeeks => AppConstants.objectiveDurationWeeks;
  int get plannedVowCount => plannedVows.length;
  int get remainingWeeks =>
      (AppConstants.objectiveDurationWeeks - completedWeeks).clamp(
        0,
        AppConstants.objectiveDurationWeeks,
      );
  double get progressRatio =>
      completedWeeks / AppConstants.objectiveDurationWeeks;

  Objective copyWith({
    String? id,
    String? title,
    String? description,
    String? motivation,
    DateTime? createdAt,
    List<PlannedVow>? plannedVows,
    int? completedWeeks,
    int? failedWeeks,
    int? health,
    bool? isCompleted,
  }) {
    return Objective(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      motivation: motivation ?? this.motivation,
      createdAt: createdAt ?? this.createdAt,
      plannedVows: plannedVows ?? this.plannedVows,
      completedWeeks: completedWeeks ?? this.completedWeeks,
      failedWeeks: failedWeeks ?? this.failedWeeks,
      health: health ?? this.health,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'motivation': motivation,
    'createdAt': createdAt.toIso8601String(),
    'plannedVows': plannedVows.map((vow) => vow.toJson()).toList(),
    'completedWeeks': completedWeeks,
    'failedWeeks': failedWeeks,
    'health': health,
    'isCompleted': isCompleted,
  };

  factory Objective.fromJson(Map<String, dynamic> json) {
    return Objective(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      motivation: json['motivation'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      plannedVows: (json['plannedVows'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) =>
                PlannedVow.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      completedWeeks: (json['completedWeeks'] as num?)?.toInt() ?? 0,
      failedWeeks: (json['failedWeeks'] as num?)?.toInt() ?? 0,
      health:
          (json['health'] as num?)?.toInt() ??
          AppConstants.initialProjectHealth,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class WeeklyVow {
  const WeeklyVow({
    required this.id,
    required this.sourceObjectiveId,
    required this.sourceObjectiveTitle,
    required this.sourcePlannedVowId,
    required this.title,
    required this.launchedAt,
    required this.checkInDays,
  });

  final String id;
  final String sourceObjectiveId;
  final String sourceObjectiveTitle;
  final String sourcePlannedVowId;
  final String title;
  final DateTime launchedAt;
  final List<String> checkInDays;

  int get checkInCount => checkInDays.length;
  bool checkedToday(DateTime now) => checkInDays.contains(_dateKey(now));
  bool get meetsWeeklyThreshold =>
      checkInCount >= AppConstants.weeklyValidationTarget;

  WeeklyVow copyWith({
    String? id,
    String? sourceObjectiveId,
    String? sourceObjectiveTitle,
    String? sourcePlannedVowId,
    String? title,
    DateTime? launchedAt,
    List<String>? checkInDays,
  }) {
    return WeeklyVow(
      id: id ?? this.id,
      sourceObjectiveId: sourceObjectiveId ?? this.sourceObjectiveId,
      sourceObjectiveTitle: sourceObjectiveTitle ?? this.sourceObjectiveTitle,
      sourcePlannedVowId: sourcePlannedVowId ?? this.sourcePlannedVowId,
      title: title ?? this.title,
      launchedAt: launchedAt ?? this.launchedAt,
      checkInDays: checkInDays ?? this.checkInDays,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceObjectiveId': sourceObjectiveId,
    'sourceObjectiveTitle': sourceObjectiveTitle,
    'sourcePlannedVowId': sourcePlannedVowId,
    'title': title,
    'launchedAt': launchedAt.toIso8601String(),
    'checkInDays': checkInDays,
  };

  factory WeeklyVow.fromJson(Map<String, dynamic> json) {
    return WeeklyVow(
      id: json['id'] as String,
      sourceObjectiveId: json['sourceObjectiveId'] as String,
      sourceObjectiveTitle: json['sourceObjectiveTitle'] as String? ?? '',
      sourcePlannedVowId: json['sourcePlannedVowId'] as String? ?? '',
      title: json['title'] as String,
      launchedAt: DateTime.parse(json['launchedAt'] as String),
      checkInDays: (json['checkInDays'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class WeekVowStat {
  const WeekVowStat({
    required this.objectiveId,
    required this.objectiveTitle,
    required this.plannedVowId,
    required this.vowTitle,
    required this.checkedDays,
    required this.success,
  });

  final String objectiveId;
  final String objectiveTitle;
  final String plannedVowId;
  final String vowTitle;
  final int checkedDays;
  final bool success;

  Map<String, dynamic> toJson() => {
    'objectiveId': objectiveId,
    'objectiveTitle': objectiveTitle,
    'plannedVowId': plannedVowId,
    'vowTitle': vowTitle,
    'checkedDays': checkedDays,
    'success': success,
  };

  factory WeekVowStat.fromJson(Map<String, dynamic> json) {
    return WeekVowStat(
      objectiveId: json['objectiveId'] as String? ?? '',
      objectiveTitle: json['objectiveTitle'] as String,
      plannedVowId: json['plannedVowId'] as String? ?? '',
      vowTitle: json['vowTitle'] as String,
      checkedDays: (json['checkedDays'] as num).toInt(),
      success: json['success'] as bool,
    );
  }
}

class WeekHistoryEntry {
  const WeekHistoryEntry({
    required this.id,
    required this.launchedAt,
    required this.completedAt,
    required this.success,
    required this.xpGained,
    required this.penaltyPaid,
    required this.streakReset,
    required this.vowStats,
    required this.objectiveIds,
  });

  final String id;
  final DateTime launchedAt;
  final DateTime completedAt;
  final bool success;
  final int xpGained;
  final int penaltyPaid;
  final bool streakReset;
  final List<WeekVowStat> vowStats;
  final List<String> objectiveIds;

  String get statusLabel => success ? 'Réussie' : 'À améliorer';
  String get badgeLabel => success ? '✅ Réussie' : '⚠ À améliorer';

  Map<String, dynamic> toJson() => {
    'id': id,
    'launchedAt': launchedAt.toIso8601String(),
    'completedAt': completedAt.toIso8601String(),
    'success': success,
    'xpGained': xpGained,
    'penaltyPaid': penaltyPaid,
    'streakReset': streakReset,
    'vowStats': vowStats.map((item) => item.toJson()).toList(),
    'objectiveIds': objectiveIds,
  };

  factory WeekHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WeekHistoryEntry(
      id: json['id'] as String,
      launchedAt: DateTime.parse(json['launchedAt'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
      success: json['success'] as bool,
      xpGained: (json['xpGained'] as num?)?.toInt() ?? 0,
      penaltyPaid: (json['penaltyPaid'] as num?)?.toInt() ?? 0,
      streakReset: json['streakReset'] as bool? ?? false,
      vowStats: (json['vowStats'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) =>
                WeekVowStat.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      objectiveIds:
          (json['objectiveIds'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(),
    );
  }
}

class AppSnapshot {
  const AppSnapshot({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.pushEnabled,
    required this.xp,
    required this.discipline,
    required this.projectHealth,
    required this.currentStreak,
    required this.totalPenalties,
    required this.totalSavings,
    required this.createdAt,
    required this.updatedAt,
    required this.objectives,
    required this.activeWeeklyVows,
    required this.history,
    required this.activeWeekId,
    required this.activeWeekLaunchedAt,
  });

  final String? userId;
  final String displayName;
  final String email;
  final bool pushEnabled;
  final int xp;
  final int discipline;
  final int projectHealth;
  final int currentStreak;
  final int totalPenalties;
  final int totalSavings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Objective> objectives;
  final List<WeeklyVow> activeWeeklyVows;
  final List<WeekHistoryEntry> history;
  final String? activeWeekId;
  final DateTime? activeWeekLaunchedAt;

  factory AppSnapshot.initial({
    String? userId,
    String? displayName,
    String? email,
  }) {
    final now = DateTime.now();
    return AppSnapshot(
      userId: userId,
      displayName: displayName ?? 'Utilisateur',
      email: email ?? '',
      pushEnabled: true,
      xp: 0,
      discipline: AppConstants.initialDiscipline,
      projectHealth: AppConstants.initialProjectHealth,
      currentStreak: 0,
      totalPenalties: 0,
      totalSavings: 0,
      createdAt: now,
      updatedAt: now,
      objectives: const <Objective>[],
      activeWeeklyVows: const <WeeklyVow>[],
      history: const <WeekHistoryEntry>[],
      activeWeekId: null,
      activeWeekLaunchedAt: null,
    );
  }

  int get level => xp ~/ AppConstants.xpPerLevel;
  int get xpIntoLevel => xp % AppConstants.xpPerLevel;
  int get xpForNextLevel => AppConstants.xpPerLevel;
  int get activeObjectivesCount =>
      objectives.where((objective) => !objective.isCompleted).length;
  int get completedObjectivesCount =>
      objectives.where((objective) => objective.isCompleted).length;
  List<Objective> get activeObjectives =>
      objectives.where((objective) => !objective.isCompleted).toList();
  bool get hasActiveWeek => activeWeeklyVows.isNotEmpty;
  bool get canLaunchNewWeek {
    if (activeWeekLaunchedAt == null) {
      return true;
    }
    return DateTime.now().difference(activeWeekLaunchedAt!).inDays >=
        AppConstants.weekLockDays;
  }

  int get totalSuccessfulWeeks =>
      history.where((entry) => entry.success).length;
  int get totalFailedWeeks => history.where((entry) => !entry.success).length;

  AppSnapshot copyWith({
    bool clearUserId = false,
    String? userId,
    String? displayName,
    String? email,
    bool? pushEnabled,
    int? xp,
    int? discipline,
    int? projectHealth,
    int? currentStreak,
    int? totalPenalties,
    int? totalSavings,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Objective>? objectives,
    List<WeeklyVow>? activeWeeklyVows,
    List<WeekHistoryEntry>? history,
    bool clearActiveWeekId = false,
    String? activeWeekId,
    bool clearActiveWeekLaunchedAt = false,
    DateTime? activeWeekLaunchedAt,
  }) {
    return AppSnapshot(
      userId: clearUserId ? null : (userId ?? this.userId),
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      xp: xp ?? this.xp,
      discipline: discipline ?? this.discipline,
      projectHealth: projectHealth ?? this.projectHealth,
      currentStreak: currentStreak ?? this.currentStreak,
      totalPenalties: totalPenalties ?? this.totalPenalties,
      totalSavings: totalSavings ?? this.totalSavings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      objectives: objectives ?? this.objectives,
      activeWeeklyVows: activeWeeklyVows ?? this.activeWeeklyVows,
      history: history ?? this.history,
      activeWeekId: clearActiveWeekId
          ? null
          : (activeWeekId ?? this.activeWeekId),
      activeWeekLaunchedAt: clearActiveWeekLaunchedAt
          ? null
          : (activeWeekLaunchedAt ?? this.activeWeekLaunchedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'email': email,
    'pushEnabled': pushEnabled,
    'xp': xp,
    'discipline': discipline,
    'projectHealth': projectHealth,
    'currentStreak': currentStreak,
    'totalPenalties': totalPenalties,
    'totalSavings': totalSavings,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'objectives': objectives.map((objective) => objective.toJson()).toList(),
    'activeWeeklyVows': activeWeeklyVows.map((vow) => vow.toJson()).toList(),
    'history': history.map((entry) => entry.toJson()).toList(),
    'activeWeekId': activeWeekId,
    'activeWeekLaunchedAt': activeWeekLaunchedAt?.toIso8601String(),
  };

  String encode() => jsonEncode(toJson());

  factory AppSnapshot.fromJson(Map<String, dynamic> json) {
    return AppSnapshot(
      userId: json['userId'] as String?,
      displayName: json['displayName'] as String? ?? 'Utilisateur',
      email: json['email'] as String? ?? '',
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      discipline:
          (json['discipline'] as num?)?.toInt() ??
          AppConstants.initialDiscipline,
      projectHealth:
          (json['projectHealth'] as num?)?.toInt() ??
          AppConstants.initialProjectHealth,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      totalPenalties: (json['totalPenalties'] as num?)?.toInt() ?? 0,
      totalSavings: (json['totalSavings'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      objectives: (json['objectives'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) =>
                Objective.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      activeWeeklyVows:
          (json['activeWeeklyVows'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (item) =>
                    WeeklyVow.fromJson(Map<String, dynamic>.from(item as Map)),
              )
              .toList(),
      history: (json['history'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => WeekHistoryEntry.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      activeWeekId: json['activeWeekId'] as String?,
      activeWeekLaunchedAt: json['activeWeekLaunchedAt'] == null
          ? null
          : DateTime.parse(json['activeWeekLaunchedAt'] as String),
    );
  }
}
