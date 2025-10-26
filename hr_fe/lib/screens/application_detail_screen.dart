import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/criteria.dart';
import '../services/api.dart';
import '../services/auth_state.dart';
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
            final from = (widget.initialScores is Map<String, dynamic>)
                ? (widget.initialScores as Map<String, dynamic>)['from']?.toString()
                : null;
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
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _cancel,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Hủy ứng tuyển'),
            ),
          ),
        ),
      ),
    );
  }
}
