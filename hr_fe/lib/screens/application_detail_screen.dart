import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/criteria.dart';
import '../services/api.dart';
import '../services/auth_state.dart';
import '../services/notifications_state.dart';
import '../widgets/resume_view.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final int appId;
  final Map<String, dynamic>? initialScores;
  const ApplicationDetailScreen({super.key, required this.appId, this.initialScores});
  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  Map<String, dynamic>? app;
  Map<String, dynamic>? job;
  Map<String, dynamic>? poster;
  Map<String, dynamic>? profile;
  bool loading = true;
  String? error;
  List<CriteriaDef> _criteria = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      try {
        _criteria = await fetchCriteria();
      } catch (_) {
        _criteria = const [];
      }
      app = await apiGet('/applications/${widget.appId}');
      if (app != null) {
        job = await apiGet('/jobs/${app!['job_id']}');
        final posterId = job?['posted_by'];
        if (posterId != null) {
          try {
            poster = await apiGet('/users/$posterId/summary');
          } catch (_) {
            // may be restricted
          }
        }
        try {
          final email = app!['email']?.toString();
          if (email != null && email.isNotEmpty) {
            if (!mounted) return; // avoid using context after async gaps
            final role = context.read<AuthState>().role;
            final meEmail = context.read<AuthState>().user?['email']?.toString();
            if (role == 'candidate' && meEmail != null && meEmail.toLowerCase() == email.toLowerCase()) {
              // Candidate viewing their own application: use /profiles/me to avoid 403
              try {
                profile = await apiGet('/profiles/me');
              } catch (_) {
                try {
                  profile = await apiGet('/profiles/by-email', params: {'email': email});
                } catch (__) {}
              }
            } else {
              profile = await apiGet('/profiles/by-email', params: {'email': email});
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      error = 'Không tải được chi tiết ứng tuyển';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hủy ứng tuyển'),
        content: const Text('Bạn có chắc muốn hủy ứng tuyển này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Không')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Hủy')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await apiPut('/applications/${widget.appId}', {'status': 'canceled'});
    } catch (_) {
      try {
        await apiDelete('/applications/${widget.appId}');
      } catch (__) {}
    }
    if (!mounted) return;
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy ứng tuyển')));
  }

  Future<void> _rejectCandidate() async {
    String notes = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Loại ứng viên'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bạn có chắc muốn loại ứng viên này?'),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)'),
              onChanged: (v) => notes = v,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await apiPost('/results', {
        'application_id': widget.appId,
        'result': 'rejected',
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã loại ứng viên')));
      // Refresh notifications so unread badge updates quickly
      try { context.read<NotificationsState>().fetch(); } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi loại ứng viên: $e')));
    }
  }

  Future<void> _sendOffer() async {
    DateTime startDate = DateTime.now();
    final positionCtrl = TextEditingController(text: job?['title']?.toString() ?? '');
    final salaryCtrl = TextEditingController();
    final contentCtrl = TextEditingController(
      text: 'Xin chào ${app?['full_name'] ?? ''},\nChúng tôi trân trọng mời bạn vào vị trí ${job?['title'] ?? ''}.',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Gửi thư offer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: positionCtrl,
                  decoration: const InputDecoration(labelText: 'Vị trí (tuỳ chọn)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: salaryCtrl,
                  decoration: const InputDecoration(labelText: 'Mức lương (tuỳ chọn)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Text('Ngày bắt đầu: ${startDate.toIso8601String().substring(0, 10)}')),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (picked != null) setState(() => startDate = picked);
                      },
                      child: const Text('Chọn ngày'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(labelText: 'Nội dung (tuỳ chọn)'),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gửi')),
          ],
        ),
      ),
    );

    if (ok != true) return;
    try {
      final body = {
        'application_id': widget.appId,
        'start_date': startDate.toIso8601String().substring(0, 10),
        if (positionCtrl.text.trim().isNotEmpty) 'position': positionCtrl.text.trim(),
        if (salaryCtrl.text.trim().isNotEmpty) 'salary': double.tryParse(salaryCtrl.text.trim()),
        if (contentCtrl.text.trim().isNotEmpty) 'content': contentCtrl.text.trim(),
      };
      await apiPost('/offers', body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi thư offer')));
      // Refresh notifications so unread badge updates quickly
      try { context.read<NotificationsState>().fetch(); } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi gửi offer: $e')));
    }
  }

  // no-op: label resolver removed after switching to ResumeView

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(c).canPop()) {
              c.pop();
              return;
            }
      final from = widget.initialScores?['from']?.toString();
            if (from == '/evaluations') {
              c.go('/evaluations');
            } else {
              c.go('/applications');
            }
          },
        ),
        title: const Text('Chi tiết ứng tuyển'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Always-visible header to avoid blank appearance
                    Text('Ứng tuyển #${widget.appId}', style: Theme.of(c).textTheme.titleLarge),
                    const SizedBox(height: 8),

                    if (job != null) ...[
                      Text(job!['title']?.toString() ?? '', style: Theme.of(c).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(job!['department']?.toString() ?? ''),
                      Text(job!['location']?.toString() ?? ''),
                      const SizedBox(height: 8),
                      Text(job!['description']?.toString() ?? ''),
                      const Divider(height: 24),
                    ],

                    if (poster != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline),
                        title: Text(poster!['full_name']?.toString() ?? ''),
                        subtitle: Text(poster!['email']?.toString() ?? ''),
                      ),
                    if (poster == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Không thể hiển thị thông tin người tuyển dụng (quyền hạn hạn chế)',
                          style: Theme.of(c).textTheme.bodySmall,
                        ),
                      ),

                    if (app != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(app!['full_name']?.toString() ?? '', style: Theme.of(c).textTheme.titleMedium),
                              Text(
                                  '${app!['email'] ?? ''} • Trạng thái: ${app!['status'] ?? ''}${job != null ? '\nCông việc: ${job!['title'] ?? ''}' : ''}'),
                              if ((app!['phone']?.toString() ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text('SĐT: ${app!['phone']}'),
                                ),
                              if ((app!['resume_url']?.toString() ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      const Text('CV: '),
                                      Expanded(
                                        child: Text(
                                          app!['resume_url']?.toString() ?? '',
                                          style: const TextStyle(decoration: TextDecoration.underline),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy),
                                        tooltip: 'Sao chép link',
                                        onPressed: () => Clipboard.setData(ClipboardData(text: app!['resume_url']?.toString() ?? '')),
                                      )
                                    ],
                                  ),
                                ),
                              if ((app!['cover_letter']?.toString() ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text('Thư ứng tuyển:\n${app!['cover_letter']}'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Hồ sơ thí sinh', style: Theme.of(c).textTheme.titleMedium)),
                    const SizedBox(height: 6),
                    Builder(builder: (_) {
                      // Combine profile data with any initialScores fallback from navigation args
                      final Map<String, dynamic> combinedProfile = profile == null
                          ? <String, dynamic>{}
                          : Map<String, dynamic>.from(profile!);
                      if (combinedProfile['scores'] == null && widget.initialScores?['scores'] is Map) {
                        combinedProfile['scores'] = widget.initialScores!['scores'];
                      }
                      if (combinedProfile.isEmpty) return const Text('Chưa có hồ sơ');
                      return ResumeView(app: app, profile: combinedProfile, job: job, criteria: _criteria);
                    }),
                    const SizedBox(height: 80), // padding to avoid bottom button overlay
                  ],
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Builder(
            builder: (ctx) {
              final role = context.watch<AuthState>().role;
              if (role == 'recruiter' || role == 'admin') {
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _rejectCandidate,
                        icon: const Icon(Icons.block),
                        label: const Text('Loại ứng viên'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _sendOffer,
                        icon: const Icon(Icons.mark_email_unread_outlined),
                        label: const Text('Gửi thư offer'),
                      ),
                    ),
                  ],
                );
              }
              // Candidate view: show cancel application
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _cancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Hủy ứng tuyển'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
