import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../models/app_models.dart';

class SyncService {
  SyncService(this.client);

  final SupabaseClient client;
  final Uuid _uuid = const Uuid();
  static const String _namespaceUrl = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

  Future<void> pushSnapshot(AppSnapshot snapshot) async {
    final userId = snapshot.userId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    final updatedAt = DateTime.now().toIso8601String();

    await client.from('profiles').upsert({
      'id': userId,
      'full_name': snapshot.displayName,
      'email': snapshot.email,
      'push_enabled': snapshot.pushEnabled,
      'discipline': snapshot.discipline,
      'project_health': snapshot.projectHealth,
      'current_streak': snapshot.currentStreak,
      'total_xp': snapshot.xp,
      'total_penalties': snapshot.totalPenalties,
      'total_savings': snapshot.totalSavings,
      'updated_at': updatedAt,
    }, onConflict: 'id');

    await client.from('app_snapshots').upsert({
      'user_id': userId,
      'payload': snapshot.toJson(),
      'updated_at': updatedAt,
    }, onConflict: 'user_id');

    final objectiveRows = snapshot.objectives.map((objective) {
      return {
        'id': objective.id,
        'user_id': userId,
        'title': objective.title,
        'description': objective.description,
        'motivation': objective.motivation,
        'target_weeks': AppConstants.objectiveDurationWeeks,
        'completed_weeks': objective.completedWeeks,
        'failed_weeks': objective.failedWeeks,
        'health': objective.health,
        'is_completed': objective.isCompleted,
        'created_at': objective.createdAt.toIso8601String(),
        'updated_at': updatedAt,
      };
    }).toList();
    if (objectiveRows.isNotEmpty) {
      await client.from('objectives').upsert(objectiveRows, onConflict: 'id');
    }

    final plannedVowRows = snapshot.objectives
        .expand(
          (objective) => objective.plannedVows.map((plannedVow) {
            return {
              'id': plannedVow.id,
              'user_id': userId,
              'objective_id': objective.id,
              'week_index': plannedVow.weekIndex,
              'title': plannedVow.title,
              'created_at': updatedAt,
              'updated_at': updatedAt,
            };
          }),
        )
        .toList();
    if (plannedVowRows.isNotEmpty) {
      await client.from('planned_vows').upsert(plannedVowRows, onConflict: 'id');
    }

    if (snapshot.activeWeekId != null && snapshot.activeWeeklyVows.isNotEmpty) {
      final lockedUntil = snapshot.activeWeekLaunchedAt == null
          ? DateTime.now().add(const Duration(days: 7)).toIso8601String()
          : snapshot.activeWeekLaunchedAt!
                .add(const Duration(days: 7))
                .toIso8601String();

      final activeCycleRow = {
        'id': snapshot.activeWeekId,
        'user_id': userId,
        'launched_at':
            snapshot.activeWeekLaunchedAt?.toIso8601String() ?? updatedAt,
        'completed_at': null,
        'locked_until': lockedUntil,
        'status': 'active',
        'is_success': null,
        'penalty_paid': 0,
        'xp_gained': 0,
        'streak_reset': false,
        'created_at': updatedAt,
        'updated_at': updatedAt,
      };
      await client.from('weekly_cycles').upsert(activeCycleRow, onConflict: 'id');

      final activeWeeklyRows = snapshot.activeWeeklyVows.map((vow) {
        return {
          'id': vow.id,
          'user_id': userId,
          'weekly_cycle_id': snapshot.activeWeekId,
          'objective_id': vow.sourceObjectiveId,
          'planned_vow_id': vow.sourcePlannedVowId,
          'title': vow.title,
          'check_in_count': vow.checkInCount,
          'is_completed': vow.meetsWeeklyThreshold,
          'created_at': vow.launchedAt.toIso8601String(),
          'updated_at': updatedAt,
        };
      }).toList();
      if (activeWeeklyRows.isNotEmpty) {
        await client.from('weekly_vows').upsert(activeWeeklyRows, onConflict: 'id');
      }

      final checkInRows = snapshot.activeWeeklyVows
          .expand(
            (vow) => vow.checkInDays.map((checkedOn) {
              return {
                'id': _uuid.v4(),
                'user_id': userId,
                'weekly_vow_id': vow.id,
                'checked_on': checkedOn,
                'created_at': updatedAt,
                'updated_at': updatedAt,
              };
            }),
          )
          .toList();
      if (checkInRows.isNotEmpty) {
        await client.from('check_ins').upsert(checkInRows, onConflict: 'id');
      }
    }

    if (snapshot.history.isNotEmpty) {
      final completedCycleRows = snapshot.history.map((entry) {
        return {
          'id': entry.id,
          'user_id': userId,
          'launched_at': entry.launchedAt.toIso8601String(),
          'completed_at': entry.completedAt.toIso8601String(),
          'locked_until': entry.completedAt.toIso8601String(),
          'status': 'completed',
          'is_success': entry.success,
          'penalty_paid': entry.penaltyPaid,
          'xp_gained': entry.xpGained,
          'streak_reset': entry.streakReset,
          'created_at': entry.completedAt.toIso8601String(),
          'updated_at': updatedAt,
        };
      }).toList();
      await client.from('weekly_cycles').upsert(completedCycleRows, onConflict: 'id');

      final completedWeeklyRows = snapshot.history
          .expand(
            (entry) => entry.vowStats.asMap().entries.map((entryData) {
              final weeklyVowId = _historyWeeklyVowId(entry.id, entryData.key);
              return {
                'id': weeklyVowId,
                'user_id': userId,
                'weekly_cycle_id': entry.id,
                'objective_id': entryData.value.objectiveId,
                'planned_vow_id': entryData.value.plannedVowId,
                'title': entryData.value.vowTitle,
                'check_in_count': entryData.value.checkedDays,
                'is_completed': entryData.value.success,
                'created_at': entry.completedAt.toIso8601String(),
                'updated_at': updatedAt,
              };
            }),
          )
          .toList();
      if (completedWeeklyRows.isNotEmpty) {
        await client.from('weekly_vows').upsert(completedWeeklyRows, onConflict: 'id');
      }

      final checkInRows = snapshot.history
          .expand(
            (entry) => entry.vowStats.asMap().entries.expand((entryData) {
              final weeklyVowId = _historyWeeklyVowId(entry.id, entryData.key);
              return List.generate(entryData.value.checkedDays, (dayIndex) {
                final checkedOn = DateTime(
                  entry.completedAt.year,
                  entry.completedAt.month,
                  entry.completedAt.day,
                ).subtract(Duration(days: entryData.value.checkedDays - dayIndex - 1));
                return {
                  'id': _uuid.v4(),
                  'user_id': userId,
                  'weekly_vow_id': weeklyVowId,
                  'checked_on': checkedOn.toIso8601String().split('T').first,
                  'created_at': entry.completedAt.toIso8601String(),
                  'updated_at': updatedAt,
                };
              });
            }),
          )
          .toList();
      if (checkInRows.isNotEmpty) {
        await client.from('check_ins').upsert(checkInRows, onConflict: 'weekly_vow_id,checked_on');
      }
    }
  }

  Future<AppSnapshot?> pullSnapshot(String userId) async {
    final snapshotRow = await client
        .from('app_snapshots')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (snapshotRow != null) {
      final payload = snapshotRow['payload'];
      if (payload is Map) {
        final data = Map<String, dynamic>.from(payload as Map);
        data['userId'] = userId;
        return AppSnapshot.fromJson(data);
      }
      if (payload is String && payload.isNotEmpty) {
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          decoded['userId'] = userId;
          return AppSnapshot.fromJson(decoded);
        }
      }
    }

    final profile = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (profile == null) {
      return null;
    }

    final objectivesRows = await client
        .from('objectives')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    final plannedRows = await client
        .from('planned_vows')
        .select()
        .eq('user_id', userId)
        .order('week_index');
    final cyclesRows = await client
        .from('weekly_cycles')
        .select()
        .eq('user_id', userId)
        .order('launched_at');
    final weeklyRows = await client
        .from('weekly_vows')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    final checkInRows = await client
        .from('check_ins')
        .select()
        .eq('user_id', userId)
        .order('checked_on');

    final objectives = <Objective>[];
    final objectiveById = <String, Objective>{};
    for (final row in objectivesRows) {
      final objectiveId = row['id'] as String;
      final objectivePlannedRows = plannedRows
          .where((plannedRow) => plannedRow['objective_id'] == objectiveId)
          .toList();
      final objective = Objective.fromJson({
        'id': objectiveId,
        'title': row['title'] as String,
        'description': row['description'] as String? ?? '',
        'motivation': row['motivation'] as String? ?? '',
        'createdAt': row['created_at'] as String,
        'plannedVows': objectivePlannedRows
            .map(
              (plannedRow) => {
                'id': plannedRow['id'],
                'title': plannedRow['title'],
                'weekIndex': plannedRow['week_index'],
              },
            )
            .toList(),
        'completedWeeks': row['completed_weeks'] as num? ?? 0,
        'failedWeeks': row['failed_weeks'] as num? ?? 0,
        'health': row['health'] as num? ?? AppConstants.initialProjectHealth,
        'isCompleted': row['is_completed'] as bool? ?? false,
      });
      objectives.add(objective);
      objectiveById[objective.id] = objective;
    }

    final plannedById = <String, PlannedVow>{};
    for (final objective in objectives) {
      for (final planned in objective.plannedVows) {
        plannedById[planned.id] = planned;
      }
    }

    final checkInsByWeeklyVow = <String, List<String>>{};
    for (final row in checkInRows) {
      final weeklyVowId = row['weekly_vow_id'] as String;
      final checkedOn = row['checked_on'] as String;
      checkInsByWeeklyVow
          .putIfAbsent(weeklyVowId, () => <String>[])
          .add(checkedOn);
    }

    final weeklyByCycle = <String, List<Map<String, dynamic>>>{};
    for (final row in weeklyRows.cast<Map<String, dynamic>>()) {
      final cycleId = row['weekly_cycle_id'] as String;
      weeklyByCycle
          .putIfAbsent(cycleId, () => <Map<String, dynamic>>[])
          .add(row);
    }

    Map<String, dynamic>? activeCycleRow;
    for (final row in cyclesRows.cast<Map<String, dynamic>>()) {
      if (row['status'] == 'active') {
        activeCycleRow = row;
      }
    }

    WeeklyVow buildWeeklyVow(Map<String, dynamic> row) {
      final objectiveId = row['objective_id'] as String;
      final plannedVowId = row['planned_vow_id'] as String;
      final objective = objectiveById[objectiveId];
      return WeeklyVow(
        id: row['id'] as String,
        sourceObjectiveId: objectiveId,
        sourceObjectiveTitle: objective?.title ?? '',
        sourcePlannedVowId: plannedVowId,
        title: row['title'] as String,
        launchedAt: DateTime.parse(row['created_at'] as String),
        checkInDays:
            checkInsByWeeklyVow[row['id'] as String] ?? const <String>[],
      );
    }

    final activeWeeklyVows = activeCycleRow == null
        ? const <WeeklyVow>[]
        : (weeklyByCycle[activeCycleRow['id'] as String] ??
                  const <Map<String, dynamic>>[])
              .map(buildWeeklyVow)
              .toList();

    final history = cyclesRows.where((row) => row['status'] == 'completed').map(
      (cycleRow) {
        final cycleId = cycleRow['id'] as String;
        final weeklyRowsForCycle =
            weeklyByCycle[cycleId] ?? const <Map<String, dynamic>>[];
        return WeekHistoryEntry(
          id: cycleId,
          launchedAt: DateTime.parse(cycleRow['launched_at'] as String),
          completedAt: DateTime.parse(
            (cycleRow['completed_at'] ?? cycleRow['updated_at']) as String,
          ),
          success: cycleRow['is_success'] as bool? ?? false,
          xpGained: (cycleRow['xp_gained'] as num?)?.toInt() ?? 0,
          penaltyPaid: (cycleRow['penalty_paid'] as num?)?.toInt() ?? 0,
          streakReset: cycleRow['streak_reset'] as bool? ?? false,
          vowStats: weeklyRowsForCycle.map((row) {
            final objectiveId = row['objective_id'] as String;
            final plannedVowId = row['planned_vow_id'] as String;
            final objective = objectiveById[objectiveId];
            return WeekVowStat(
              objectiveId: objectiveId,
              objectiveTitle: objective?.title ?? '',
              plannedVowId: plannedVowId,
              vowTitle: row['title'] as String,
              checkedDays: (row['check_in_count'] as num?)?.toInt() ?? 0,
              success: row['is_completed'] as bool? ?? false,
            );
          }).toList(),
          objectiveIds: weeklyRowsForCycle
              .map((row) => row['objective_id'] as String)
              .toSet()
              .toList(),
        );
      },
    ).toList();

    final profileCreatedAt = profile['created_at'] == null
        ? DateTime.now()
        : DateTime.parse(profile['created_at'] as String);
    final profileUpdatedAt = profile['updated_at'] == null
        ? profileCreatedAt
        : DateTime.parse(profile['updated_at'] as String);

    return AppSnapshot(
      userId: userId,
      displayName: profile['full_name'] as String? ?? 'Utilisateur',
      email: profile['email'] as String? ?? '',
      pushEnabled: profile['push_enabled'] as bool? ?? true,
      xp: (profile['total_xp'] as num?)?.toInt() ?? 0,
      discipline:
          (profile['discipline'] as num?)?.toInt() ??
          AppConstants.initialDiscipline,
      projectHealth:
          (profile['project_health'] as num?)?.toInt() ??
          AppConstants.initialProjectHealth,
      currentStreak: (profile['current_streak'] as num?)?.toInt() ?? 0,
      totalPenalties: (profile['total_penalties'] as num?)?.toInt() ?? 0,
      totalSavings: (profile['total_savings'] as num?)?.toInt() ?? 0,
      createdAt: profileCreatedAt,
      updatedAt: profileUpdatedAt,
      objectives: objectives,
      activeWeeklyVows: activeWeeklyVows,
      history: history,
      activeWeekId: activeCycleRow?['id'] as String?,
      activeWeekLaunchedAt: activeCycleRow == null
          ? null
          : DateTime.parse(activeCycleRow['launched_at'] as String),
    );
  }

  Future<void> deleteUserData(String userId) async {
    await Future.wait([
      client.from('check_ins').delete().eq('user_id', userId),
      client.from('weekly_vows').delete().eq('user_id', userId),
      client.from('weekly_cycles').delete().eq('user_id', userId),
      client.from('planned_vows').delete().eq('user_id', userId),
      client.from('objectives').delete().eq('user_id', userId),
      client.from('profiles').delete().eq('id', userId),
      client.from('app_snapshots').delete().eq('user_id', userId),
      client.from('notification_tokens').delete().eq('user_id', userId),
    ]);
  }

  String _historyWeeklyVowId(String cycleId, int index) {
    return _uuid.v5(_namespaceUrl, 'xvow/history/$cycleId/$index');
  }
}
