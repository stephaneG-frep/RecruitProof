import 'package:flutter/foundation.dart';

import '../models/activity.dart';
import '../services/local_database_service.dart';

enum ActivitySort { newest, oldest }

class ActivityProvider extends ChangeNotifier {
  ActivityProvider(this._database);
  final LocalDatabaseService _database;

  List<Activity> _activities = [];
  String _query = '';
  ActionType? _typeFilter;
  ActivityStatus? _statusFilter;
  DateTimeRangeFilter? _dateFilter;
  ActivitySort _sort = ActivitySort.newest;

  List<Activity> get activities => List.unmodifiable(_activities);
  String? get lastReportDate => _database.lastReportDate;
  String get query => _query;
  ActionType? get typeFilter => _typeFilter;
  ActivityStatus? get statusFilter => _statusFilter;
  DateTimeRangeFilter? get dateFilter => _dateFilter;
  ActivitySort get sort => _sort;

  List<Activity> get filteredActivities {
    final normalized = _query.trim().toLowerCase();
    final result = _activities.where((activity) {
      final matchesQuery =
          normalized.isEmpty ||
          activity.title.toLowerCase().contains(normalized) ||
          activity.platform.label.toLowerCase().contains(normalized) ||
          activity.notes.toLowerCase().contains(normalized);
      final matchesType = _typeFilter == null || activity.type == _typeFilter;
      final matchesStatus =
          _statusFilter == null || activity.status == _statusFilter;
      final matchesDate =
          _dateFilter == null ||
          (!activity.date.isBefore(_dateFilter!.start) &&
              !activity.date.isAfter(_dateFilter!.end));
      return matchesQuery && matchesType && matchesStatus && matchesDate;
    }).toList();
    result.sort(
      (a, b) => _sort == ActivitySort.newest
          ? b.date.compareTo(a.date)
          : a.date.compareTo(b.date),
    );
    return result;
  }

  Future<void> load() async {
    _activities = _database.getActivities();
    notifyListeners();
  }

  Future<void> save(Activity activity) async {
    final index = _activities.indexWhere((item) => item.id == activity.id);
    if (index < 0) {
      _activities.add(activity);
    } else {
      _activities[index] = activity;
    }
    await _database.saveActivity(activity);
    notifyListeners();
  }

  Future<void> delete(Activity activity) async {
    _activities.removeWhere((item) => item.id == activity.id);
    await _database.deleteActivity(activity.id);
    notifyListeners();
  }

  Future<void> attachProof(String activityId, String proofId) async {
    final activity = _activities.firstWhere((item) => item.id == activityId);
    if (activity.proofIds.contains(proofId)) return;
    await save(activity.copyWith(proofIds: [...activity.proofIds, proofId]));
  }

  Future<void> detachProof(String proofId) async {
    for (final activity in _activities.where(
      (item) => item.proofIds.contains(proofId),
    )) {
      await save(
        activity.copyWith(
          proofIds: activity.proofIds.where((id) => id != proofId).toList(),
        ),
      );
    }
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setTypeFilter(ActionType? value) {
    _typeFilter = value;
    notifyListeners();
  }

  void setStatusFilter(ActivityStatus? value) {
    _statusFilter = value;
    notifyListeners();
  }

  void setDateFilter(DateTimeRangeFilter? value) {
    _dateFilter = value;
    notifyListeners();
  }

  void setSort(ActivitySort value) {
    _sort = value;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _typeFilter = null;
    _statusFilter = null;
    _dateFilter = null;
    notifyListeners();
  }

  Future<void> markReportGenerated() async {
    await _database.setLastReportDate(DateTime.now());
    notifyListeners();
  }
}

class DateTimeRangeFilter {
  const DateTimeRangeFilter(this.start, this.end);
  final DateTime start;
  final DateTime end;
}
