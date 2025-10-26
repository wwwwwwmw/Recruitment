import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_state.dart';
import '../services/notifications_state.dart';

class RoleDashboard extends StatefulWidget {
  const RoleDashboard({super.key});
  @override
  State<RoleDashboard> createState() => _RoleDashboardState();
}

class _RoleDashboardState extends State<RoleDashboard> {
  bool _welcomed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_welcomed && context.read<AuthState>().isLoggedIn) {
      _welcomed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final ns = context.read<NotificationsState>();
        await ns.fetch();
        if (!mounted) return;
        if (ns.unreadCount > 0) {
          final firstUnread = ns.items.firstWhere(
              (e) => e['is_read'] == false,
              orElse: () => (ns.items.isNotEmpty ? ns.items.first : {}));
          final title = firstUnread['title']?.toString() ?? 'Bạn có thông báo mới';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$title (${ns.unreadCount} chưa đọc)'),
            action: SnackBarAction(label: 'Xem', onPressed: () => context.go('/notifications')),
          ));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthState>().role;
    final title = role == 'admin'
        ? 'Quản trị hệ thống'
        : role == 'recruiter'
            ? 'Bảng điều khiển Nhà tuyển dụng'
            : 'Bảng điều khiển Thí sinh';

    final List<_NavTile> tiles = [];
    if (role == 'admin' || role == 'recruiter') {
      tiles.addAll([
        _NavTile('Tin tuyển dụng', '/jobs', Icons.work_outline),
        _NavTile('Sàng lọc & Đánh giá', '/evaluations', Icons.rate_review_outlined),
        _NavTile('Đặt phỏng vấn', '/interviews', Icons.event_available),
      ]);
    }
    if (role == 'admin') {
      tiles.addAll([
        _NavTile('Quản lý người dùng', '/users', Icons.manage_accounts_outlined),
        _NavTile('Báo cáo', '/reports', Icons.pie_chart_outline),
        _NavTile('Tiêu chí đánh giá', '/criteria', Icons.tune),
      ]);
    }
    tiles.addAll([
      _NavTile(role == 'recruiter' ? 'Việc làm của tôi' : 'Việc làm', role == 'recruiter' ? '/my-jobs' : '/jobs', Icons.work_history_outlined),
      if (role == 'recruiter') _NavTile('Ứng viên của tôi', '/my-candidates', Icons.people_outline),
      if (role != 'recruiter') _NavTile('Ứng tuyển của tôi', '/applications', Icons.assignment_outlined),
      if (role == 'candidate') _NavTile('Hồ sơ của tôi', '/my-profile', Icons.badge_outlined),
      _NavTile('Thông báo', '/notifications', Icons.notifications_active_outlined),
      _NavTile('Kết quả', '/results', Icons.verified_outlined),
    ]);

    final unread = context.watch<NotificationsState>().unreadCount;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: () => context.go('/notifications'),
            icon: Stack(children: [
              const Icon(Icons.notifications_outlined),
              if (unread > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 11), textAlign: TextAlign.center),
                  ),
                ),
            ]),
            tooltip: 'Thông báo',
          ),
          TextButton.icon(
            onPressed: () => context.read<AuthState>().logout(),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        children: tiles.map((t) => _Tile(t: t)).toList(),
      ),
    );
  }
}

class _NavTile {
  final String label;
  final String route;
  final IconData icon;
  _NavTile(this.label, this.route, this.icon);
}

class _Tile extends StatelessWidget {
  final _NavTile t;
  const _Tile({required this.t});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go(t.route),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(t.icon, size: 48),
            const SizedBox(height: 12),
            Text(t.label, textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}
