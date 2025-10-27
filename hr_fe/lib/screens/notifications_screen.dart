import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/notifications_state.dart';
import '../services/auth_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<NotificationsState>().fetch();
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ns = context.watch<NotificationsState>();
    final meId = context.watch<AuthState>().user?['id'] as int?;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text('Thông báo (${ns.unreadCount} chưa đọc)'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: ns.items.length,
              itemBuilder: (ctx, i) {
                final n = ns.items[i];
                final mine = (n['recipient_id'] == meId) || (n['user_id'] == meId);
                // Chọn icon: offer -> mail; phỏng vấn -> giữ nguyên chuông; khác -> mặc định theo trạng thái đọc
                IconData _iconFor(Map<String,dynamic> n){
                  final t = (n['type']?.toString() ?? '').toLowerCase();
                  if (t.startsWith('offer.')) return Icons.mail_outline;
                  // interview.* giữ nguyên theo trạng thái đọc
                  return n['is_read'] == true ? Icons.notifications_none : Icons.notifications_active_outlined;
                }
                return ListTile(
                  leading: Icon(_iconFor(n)),
                  title: Text(n['title']?.toString() ?? ''),
                  subtitle: Text(n['message']?.toString() ?? ''),
                  trailing: (n['is_read'] == true || !mine)
                      ? null
                      : TextButton(
                          onPressed: () => ns.markRead(n['id'] as int),
                          child: const Text('Đã đọc'),
                        ),
                );
              },
            ),
    );
  }
}
