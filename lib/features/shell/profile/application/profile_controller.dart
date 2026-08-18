import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/features/shell/profile/data/profile_demo_data.dart';

/// Loads the profile the "حسابي" tab renders.
///
/// It is an [AsyncNotifier] on purpose: the demo source is local today, but the
/// three states the screen paints - loading, data, error - are exactly the ones
/// a real `GET /v1/players/me` will hand back, so wiring the repository in
/// changes [build] and nothing else.
class ProfileController extends AsyncNotifier<PlayerProfile?> {
  @override
  Future<PlayerProfile?> build() => ProfileDemoData.load();

  /// Re-reads the source. Shows the skeleton again rather than a stale card,
  /// which is what a pull-to-refresh on a money screen should do.
  Future<void> reload() async {
    state = const AsyncValue<PlayerProfile?>.loading();
    state = await AsyncValue.guard<PlayerProfile?>(ProfileDemoData.load);
  }
}

/// The profile the screen watches.
final AsyncNotifierProvider<ProfileController, PlayerProfile?>
    profileControllerProvider =
    AsyncNotifierProvider<ProfileController, PlayerProfile?>(
  ProfileController.new,
);

/// Whether the identifiers a player would not want a bystander to read - the
/// Telegram id - are shown in full.
///
/// Screen state, so it lives here and not in a widget: the toggle survives a
/// rebuild and a language switch.
class ProfileRevealController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Flips between masked and revealed.
  void toggle() {
    state = !state;
  }
}

/// False (masked) until the player asks to see the identifiers.
final NotifierProvider<ProfileRevealController, bool> profileRevealProvider =
    NotifierProvider<ProfileRevealController, bool>(ProfileRevealController.new);
