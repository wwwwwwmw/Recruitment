import 'package:flutter/foundation.dart';
import 'api.dart';

class NotificationsState extends ChangeNotifier {
	List<Map<String, dynamic>> _items = [];
	List<Map<String, dynamic>> get items => _items;

	int get unreadCount => _items.where((e) => (e['is_read'] == false)).length;

	Future<void> fetch() async {
		final list = await apiGetList('/notifications');
		_items = list.cast<Map<String, dynamic>>();
		notifyListeners();
	}

	Future<void> markRead(int id) async {
		await apiPut('/notifications/$id/read', {});
		final idx = _items.indexWhere((e) => e['id'] == id);
		if (idx >= 0) {
			_items[idx] = { ..._items[idx], 'is_read': true };
			notifyListeners();
		}
	}
}
