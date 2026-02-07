import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for SharedPreferences
class SettingsKeys {
  static const String waterGoalGlasses = 'water_goal_glasses';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String themeMode = 'theme_mode';
}

/// Settings state
class AppSettings {
  final int waterGoalGlasses;
  final bool notificationsEnabled;
  
  const AppSettings({
    this.waterGoalGlasses = 8,
    this.notificationsEnabled = true,
  });
  
  AppSettings copyWith({
    int? waterGoalGlasses,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      waterGoalGlasses: waterGoalGlasses ?? this.waterGoalGlasses,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
  
  /// Water goal in ml
  int get waterGoalMl => waterGoalGlasses * 250;
}

/// Settings notifier for managing app settings
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;
  
  SettingsNotifier(this._prefs) : super(const AppSettings()) {
    _loadSettings();
  }
  
  void _loadSettings() {
    final waterGoal = _prefs.getInt(SettingsKeys.waterGoalGlasses) ?? 8;
    final notifications = _prefs.getBool(SettingsKeys.notificationsEnabled) ?? true;
    
    state = AppSettings(
      waterGoalGlasses: waterGoal,
      notificationsEnabled: notifications,
    );
  }
  
  Future<void> setWaterGoal(int glasses) async {
    await _prefs.setInt(SettingsKeys.waterGoalGlasses, glasses);
    state = state.copyWith(waterGoalGlasses: glasses);
  }
  
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(SettingsKeys.notificationsEnabled, enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }
}

/// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main.dart');
});

/// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

/// Water goal in glasses
final waterGoalGlassesProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).waterGoalGlasses;
});

/// Water goal in ml
final waterGoalMlProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).waterGoalMl;
});
