import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/api.dart';
import '../services/auth_state.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});
  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  int _tick = 0;
  @override
  Widget build(BuildContext c) {
    final role = c.watch<AuthState>().role;
    final params = <String, dynamic>{};
    if (role != 'admin') params['mine'] = 'true';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => c.go('/')),
        title: const Text('Ứng tuyển của tôi'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => _tick++))],
      ),
      body: FutureBuilder<List<dynamic>>(
        key: ValueKey(_tick),
        future: apiGetList('/applications', params: params),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
          var items = (snap.data ?? []).cast<Map<String, dynamic>>();
          String _viStatus(String? s){
            switch((s??'').toLowerCase()){
              case 'submitted': return 'đã nộp';
              case 'interviewing': return 'phỏng vấn';
              case 'offer': return 'thành công';
              case 'accepted': return 'đã nhận';
              case 'hired': return 'được tuyển';
              case 'failed': return 'không đạt';
              case 'rejected': return 'bị loại';
              case 'canceled': return 'đã hủy';
              case 'withdrawn': return 'đã rút';
              default: return s??'';
            }
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final a = items[i];
              return ListTile(
                title: Text(a['job_title']?.toString() ?? 'Công việc #${a['job_id']}'),
                subtitle: Text('${a['full_name'] ?? ''} • ${a['email'] ?? ''} • Trạng thái: ${_viStatus(a['status']?.toString())}'),
                onTap: role == 'candidate' ? () => c.go('/applications/${a['id']}') : null,
              );
            },
          );
        },
      ),
    );
  }
}
