import 'package:flutter/foundation.dart';

/// Notifies all bottom-nav branches to reload their data after a mutation
/// (add/edit account or asset) happens in any one of them.
///
/// The app's shell uses `StatefulShellRoute.indexedStack`, which keeps every
/// branch (list/analysis/home/asset) mounted simultaneously instead of
/// disposing them on tab switch. Without this bus, a mutation made through
/// one branch's entry point (e.g. adding a transaction from the Home tab's
/// FAB) would leave the other already-mounted branches showing stale data,
/// since each branch only reloaded its own data after its own mutations.
///
/// This is a permanent, app-lifetime singleton — it must never be disposed
/// by a screen. Screens should add/remove their own listener in
/// `initState`/`dispose`, but leave [instance] itself alone.
class DataRefreshBus extends ChangeNotifier {
  DataRefreshBus._();

  static final DataRefreshBus instance = DataRefreshBus._();

  /// Call after any successful account/asset mutation (add/edit/delete) so
  /// every listening branch can reload its own data.
  void notifyDataChanged() => notifyListeners();
}
