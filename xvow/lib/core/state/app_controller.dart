import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/local_store.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';

final localStoreProvider = Provider<LocalStore>((ref) => const LocalStore());
final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(Supabase.instance.client),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(Supabase.instance.client),
);

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

class AppState {
  const AppState({
    required this.snapshot,
    required this.isLoading,
    required this.isSyncing,
    required this.isOnline,
    this.errorMessage,
  });

  final AppSnapshot snapshot;
  final bool isLoading;
  final bool isSyncing;
  final bool isOnline;
  final String? errorMessage;

  AppState copyWith({
    AppSnapshot? snapshot,
    bool? isLoading,
    bool? isSyncing,
    bool? isOnline,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppState(
      snapshot: snapshot ?? this.snapshot,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      isOnline: isOnline ?? this.isOnline,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AppController extends Notifier<AppState> {
  final _uuid = const Uuid();

  late final LocalStore _localStore;
  late final SyncService _syncService;
  late final NotificationService _notificationService;
  late final AuthService _authService;

  @override
  AppState build() {
    _localStore = ref.read(localStoreProvider);
    _syncService = ref.read(syncServiceProvider);
    _notificationService = ref.read(notificationServiceProvider);
    _authService = ref.read(authServiceProvider);

    unawaited(_notificationService.initialize());

    ref.listen(authUserProvider, (_, next) {
      unawaited(handleAuthChange(next.asData?.value));
    });
    ref.listen(connectivityProvider, (_, next) {
      setOnline(next.asData?.value ?? false);
    });

    unawaited(bootstrap());
    return AppState(
      snapshot: AppSnapshot.initial(),
      isLoading: true,
      isSyncing: false,
      isOnline: true,
    );
  }

  AppSnapshot get snapshot => state.snapshot;
  bool get isLoading => state.isLoading;
  bool get isSyncing => state.isSyncing;
  bool get isOnline => state.isOnline;
  String? get errorMessage => state.errorMessage;

  Future<void> bootstrap() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final loaded = await _localStore.loadSnapshot();
    state = state.copyWith(
      snapshot: loaded ?? AppSnapshot.initial(),
      isLoading: false,
    );
    await _maybeSyncPull();
  }

  Future<void> handleAuthChange(User? user) async {
    if (user == null) {
      final previousUserId = state.snapshot.userId;
      if (previousUserId != null) {
        await _notificationService.clearRegistration(previousUserId);
      }
      state = state.copyWith(
        snapshot: state.snapshot.copyWith(clearUserId: true),
        clearError: true,
      );
      return;
    }

    final userId = user.id;
    final displayName =
        ((user.userMetadata?['full_name'] ?? user.userMetadata?['name'])
            as String?) ??
        'Utilisateur';
    final email = user.email ?? '';
    final local = await _localStore.loadSnapshot();
    final nextSnapshot = (local != null && local.userId == userId)
        ? local.copyWith(
            displayName: local.displayName.isEmpty
                ? displayName
                : local.displayName,
            email: email.isEmpty ? local.email : email,
            userId: userId,
          )
        : AppSnapshot.initial(
            userId: userId,
            displayName: displayName,
            email: email,
          );
    state = state.copyWith(snapshot: nextSnapshot, clearError: true);
    await _maybeSyncPull();
          if (nextSnapshot.pushEnabled) {
            await _notificationService.syncRegistration(userId);
          } else {
            await _notificationService.clearRegistration(userId);
          }
  }

  void setOnline(bool value) {
    if (state.isOnline == value) {
      return;
    }
    state = state.copyWith(isOnline: value);
    if (state.isOnline) {
      unawaited(_maybeSyncPush());
    }
  }

  Future<void> setPushEnabled(bool value) async {
    state = state.copyWith(
      snapshot: state.snapshot.copyWith(
        pushEnabled: value,
        updatedAt: DateTime.now(),
      ),
      clearError: true,
    );
    await _persist();
    final userId = state.snapshot.userId;
    if (userId != null) {
      if (value) {
        await _notificationService.syncRegistration(userId);
      } else {
        await _notificationService.clearRegistration(userId);
      }
    }
  }

  Future<void> renameProfile(String name) async {
    state = state.copyWith(
      snapshot: state.snapshot.copyWith(
        displayName: name,
        updatedAt: DateTime.now(),
      ),
      clearError: true,
    );
    await _persist();
  }

  Future<void> createObjective({
    required String title,
    required String description,
    required String motivation,
    required List<String> plannedVows,
  }) async {
    if (state.snapshot.activeObjectivesCount >=
        AppConstants.maxActiveObjectives) {
      throw StateError(
        'Vous devez terminer un objectif avant d’en créer un autre.',
      );
    }
    if (plannedVows.isEmpty) {
      throw StateError('Ajoutez au moins une promesse planifiée.');
    }

    final objective = Objective(
      id: _uuid.v4(),
      title: title.trim(),
      description: description.trim(),
      motivation: motivation.trim(),
      createdAt: DateTime.now(),
      plannedVows: plannedVows
          .take(AppConstants.maxPlannedVowsPerObjective)
          .toList()
          .asMap()
          .entries
          .map((entry) {
            return PlannedVow(
              id: _uuid.v4(),
              title: entry.value.trim(),
              weekIndex: entry.key + 1,
            );
          })
          .toList(),
      completedWeeks: 0,
      failedWeeks: 0,
      health: AppConstants.initialProjectHealth,
      isCompleted: false,
    );

    state = state.copyWith(
      snapshot: state.snapshot.copyWith(
        objectives: [...state.snapshot.objectives, objective],
        updatedAt: DateTime.now(),
      ),
      clearError: true,
    );
    await _persist();
  }

  Future<void> toggleCheckIn(String weeklyVowId) async {
    if (!state.snapshot.hasActiveWeek) {
      return;
    }
    final today = _dateKey(DateTime.now());
    final updated = state.snapshot.activeWeeklyVows.map((vow) {
      if (vow.id != weeklyVowId) {
        return vow;
      }
      final days = [...vow.checkInDays];
      if (days.contains(today)) {
        days.remove(today);
      } else {
        days.add(today);
      }
      return vow.copyWith(checkInDays: days);
    }).toList();

    state = state.copyWith(
      snapshot: state.snapshot.copyWith(
        activeWeeklyVows: updated,
        updatedAt: DateTime.now(),
      ),
      clearError: true,
    );
    await _persist();
  }

  Future<void> launchWeek(List<String> plannedVowIds) async {
    if (plannedVowIds.isEmpty) {
      throw StateError('Sélectionnez au moins une promesse.');
    }
    if (plannedVowIds.length > AppConstants.maxActiveWeeklyVows) {
      throw StateError('Vous ne pouvez pas lancer plus de 3 promesses.');
    }
    if (!state.snapshot.canLaunchNewWeek) {
      throw StateError('Cette semaine est encore verrouillée.');
    }

    if (state.snapshot.hasActiveWeek) {
      await _finalizeActiveWeek();
    }

    final selected = <WeeklyVow>[];
    for (final plannedVowId in plannedVowIds) {
      final match = _findPlannedVow(plannedVowId);
      if (match == null) {
        continue;
      }
      selected.add(
        WeeklyVow(
          id: _uuid.v4(),
          sourceObjectiveId: match.$1.id,
          sourceObjectiveTitle: match.$1.title,
          sourcePlannedVowId: match.$2.id,
          title: match.$2.title,
          launchedAt: DateTime.now(),
          checkInDays: const <String>[],
        ),
      );
    }

    state = state.copyWith(
      snapshot: state.snapshot.copyWith(
        activeWeeklyVows: selected,
        activeWeekId: _uuid.v4(),
        activeWeekLaunchedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      clearError: true,
    );
    await _persist();
  }

  Future<void> refreshWeekLifecycle() async {
    if (!state.snapshot.hasActiveWeek ||
        state.snapshot.activeWeekLaunchedAt == null) {
      return;
    }
    final age = DateTime.now().difference(state.snapshot.activeWeekLaunchedAt!);
    if (age.inDays < AppConstants.weekLockDays) {
      return;
    }
    await _finalizeActiveWeek();
  }

  Future<void> toggleObjectiveCompletion(String objectiveId) async {
    state = state.copyWith(
      snapshot: state.snapshot.copyWith(
        objectives: state.snapshot.objectives.map((objective) {
          if (objective.id != objectiveId) {
            return objective;
          }
          return objective.copyWith(
            isCompleted: true,
            health: objective.health.clamp(0, 100),
          );
        }).toList(),
        updatedAt: DateTime.now(),
      ),
      clearError: true,
    );
    await _persist();
  }

  Future<void> deleteAccount() async {
    final userId = state.snapshot.userId;
    if (userId != null) {
      await _notificationService.clearRegistration(userId);
      await _syncService.deleteUserData(userId);
    }
    await _localStore.clear();
    await _authService.deleteLocalSession();
    state = AppState(
      snapshot: AppSnapshot.initial(),
      isLoading: false,
      isSyncing: false,
      isOnline: state.isOnline,
    );
  }

  Future<void> signOut() async {
    final userId = state.snapshot.userId;
    if (userId != null) {
      await _notificationService.clearRegistration(userId);
    }
    await _authService.signOut();
  }

  Future<void> _persist() async {
    await _localStore.saveSnapshot(state.snapshot);
    unawaited(_maybeSyncPush());
  }

  Future<void> _maybeSyncPull() async {
    final userId = state.snapshot.userId;
    if (!state.isOnline || userId == null) {
      return;
    }
    try {
      state = state.copyWith(isSyncing: true, clearError: true);
      final remote = await _syncService.pullSnapshot(userId);
      if (remote != null &&
          remote.updatedAt.isAfter(state.snapshot.updatedAt)) {
        state = state.copyWith(snapshot: remote);
        await _localStore.saveSnapshot(remote);
      }
    } catch (_) {
      state = state.copyWith(
        errorMessage:
            'La synchronisation distante est momentanément indisponible.',
      );
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> _maybeSyncPush() async {
    final userId = state.snapshot.userId;
    if (!state.isOnline || userId == null) {
      return;
    }
    try {
      state = state.copyWith(isSyncing: true, clearError: true);
      await _syncService.pushSnapshot(state.snapshot);
    } catch (_) {
      state = state.copyWith(
        errorMessage:
            'L’envoi vers Supabase sera retenté dès que la connexion reviendra.',
      );
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> _finalizeActiveWeek() async {
    if (state.snapshot.activeWeeklyVows.isEmpty) {
      state = state.copyWith(
        snapshot: state.snapshot.copyWith(
          clearActiveWeekLaunchedAt: true,
          updatedAt: DateTime.now(),
        ),
      );
      await _persist();
      return;
    }

    final success = state.snapshot.activeWeeklyVows.every(
      (vow) => vow.meetsWeeklyThreshold,
    );
    final objectiveIds = state.snapshot.activeWeeklyVows
        .map((vow) => vow.sourceObjectiveId)
        .toSet()
        .toList();
    final now = DateTime.now();
    final updatedObjectives = state.snapshot.objectives.map((objective) {
      if (!objectiveIds.contains(objective.id)) {
        return objective;
      }
      if (success) {
        final nextCompleted = (objective.completedWeeks + 1).clamp(
          0,
          AppConstants.objectiveDurationWeeks,
        );
        return objective.copyWith(
          completedWeeks: nextCompleted,
          health: objective.health,
          isCompleted: nextCompleted >= AppConstants.objectiveDurationWeeks,
        );
      }
      return objective.copyWith(
        failedWeeks: objective.failedWeeks + 1,
        health: (objective.health - AppConstants.failedWeekObjectiveHealthDelta)
            .clamp(0, 100),
      );
    }).toList();

    final updatedXp = success
        ? state.snapshot.xp + AppConstants.successfulWeekXp
        : state.snapshot.xp;
    final updatedDiscipline =
        (success
                ? state.snapshot.discipline +
                      AppConstants.successfulWeekDisciplineDelta
                : state.snapshot.discipline +
                      AppConstants.failedWeekDisciplineDelta)
            .clamp(0, 1000);
    final updatedStreak = success ? state.snapshot.currentStreak + 1 : 0;
    final updatedPenalties = success
        ? state.snapshot.totalPenalties
        : state.snapshot.totalPenalties + 1;
    final updatedSavings = success
        ? state.snapshot.totalSavings + AppConstants.virtualPenaltyAmount
        : state.snapshot.totalSavings;
    final vowStats = state.snapshot.activeWeeklyVows.map((vow) {
      return WeekVowStat(
        objectiveId: vow.sourceObjectiveId,
        objectiveTitle: vow.sourceObjectiveTitle,
        plannedVowId: vow.sourcePlannedVowId,
        vowTitle: vow.title,
        checkedDays: vow.checkInCount,
        success: vow.meetsWeeklyThreshold,
      );
    }).toList();
    final historyEntry = WeekHistoryEntry(
      id: _uuid.v4(),
      launchedAt: state.snapshot.activeWeekLaunchedAt ?? now,
      completedAt: now,
      success: success,
      xpGained: success ? AppConstants.successfulWeekXp : 0,
      penaltyPaid: success ? 0 : AppConstants.virtualPenaltyAmount,
      streakReset: !success,
      vowStats: vowStats,
      objectiveIds: objectiveIds,
    );

    state = state.copyWith(
      snapshot: state.snapshot.copyWith(
        objectives: updatedObjectives,
        xp: updatedXp,
        discipline: updatedDiscipline,
        currentStreak: updatedStreak,
        totalPenalties: updatedPenalties,
        totalSavings: updatedSavings,
        history: [historyEntry, ...state.snapshot.history],
        activeWeeklyVows: const <WeeklyVow>[],
        clearActiveWeekId: true,
        clearActiveWeekLaunchedAt: true,
        updatedAt: now,
      ),
    );
    await _persist();
  }

  (Objective, PlannedVow)? _findPlannedVow(String plannedVowId) {
    for (final objective in state.snapshot.objectives) {
      for (final plannedVow in objective.plannedVows) {
        if (plannedVow.id == plannedVowId) {
          return (objective, plannedVow);
        }
      }
    }
    return null;
  }

  String _dateKey(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}
