import 'package:account_book_vibe/core/data_refresh_bus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('instance is a singleton', () {
    expect(DataRefreshBus.instance, same(DataRefreshBus.instance));
  });

  test('notifyDataChanged calls registered listeners', () {
    final bus = DataRefreshBus.instance;
    var callCount = 0;
    void listener() => callCount++;

    bus.addListener(listener);
    try {
      bus.notifyDataChanged();
      expect(callCount, 1);

      bus.notifyDataChanged();
      expect(callCount, 2);
    } finally {
      bus.removeListener(listener);
    }
  });

  test('removed listeners are not called', () {
    final bus = DataRefreshBus.instance;
    var callCount = 0;
    void listener() => callCount++;

    bus.addListener(listener);
    bus.removeListener(listener);
    bus.notifyDataChanged();

    expect(callCount, 0);
  });
}
