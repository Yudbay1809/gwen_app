import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePrivacyState {
  final bool marketingEmails;
  final bool appNotifications;
  final bool dataSharing;

  const ProfilePrivacyState({
    required this.marketingEmails,
    required this.appNotifications,
    required this.dataSharing,
  });

  ProfilePrivacyState copyWith({
    bool? marketingEmails,
    bool? appNotifications,
    bool? dataSharing,
  }) {
    return ProfilePrivacyState(
      marketingEmails: marketingEmails ?? this.marketingEmails,
      appNotifications: appNotifications ?? this.appNotifications,
      dataSharing: dataSharing ?? this.dataSharing,
    );
  }
}

class ProfilePrivacyNotifier extends Notifier<ProfilePrivacyState> {
  static const _keyMarketing = 'privacy_marketing_emails';
  static const _keyNotifications = 'privacy_app_notifications';
  static const _keySharing = 'privacy_data_sharing';

  @override
  ProfilePrivacyState build() {
    _load();
    return const ProfilePrivacyState(marketingEmails: true, appNotifications: true, dataSharing: false);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      marketingEmails: prefs.getBool(_keyMarketing) ?? true,
      appNotifications: prefs.getBool(_keyNotifications) ?? true,
      dataSharing: prefs.getBool(_keySharing) ?? false,
    );
  }

  Future<void> _save(ProfilePrivacyState next) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMarketing, next.marketingEmails);
    await prefs.setBool(_keyNotifications, next.appNotifications);
    await prefs.setBool(_keySharing, next.dataSharing);
  }

  void setMarketingEmails(bool value) {
    final next = state.copyWith(marketingEmails: value);
    state = next;
    _save(next);
  }

  void setAppNotifications(bool value) {
    final next = state.copyWith(appNotifications: value);
    state = next;
    _save(next);
  }

  void setDataSharing(bool value) {
    final next = state.copyWith(dataSharing: value);
    state = next;
    _save(next);
  }
}

final profilePrivacyProvider =
    NotifierProvider<ProfilePrivacyNotifier, ProfilePrivacyState>(ProfilePrivacyNotifier.new);
