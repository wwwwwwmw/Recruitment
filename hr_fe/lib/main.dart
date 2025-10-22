import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'services/api.dart';
import 'services/auth_state.dart';

void main() {
  runApp(const HRApp());
}

class HRApp extends StatelessWidget {
  const HRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthState(),
      child: Builder(builder: (context){
        final auth = context.watch<AuthState>();
        final router = GoRouter(
          refreshListenable: auth,
          redirect: (ctx, state){
            final loggedIn = auth.isLoggedIn;
            final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
            if (!loggedIn && !loggingIn) return '/login';
            if (loggedIn && loggingIn) return '/';
            return null;
          },
          routes: [
            GoRoute(path: '/login', builder: (_, __)=> const LoginScreen()),
            GoRoute(path: '/signup', builder: (_, __)=> const SignupScreen()),
            GoRoute(path: '/', builder: (_, __) => const RoleDashboard()),
            GoRoute(path: '/my-candidates', builder: (_, __) => const MyCandidatesScreen()),
            GoRoute(path: '/jobs/:id', builder: (ctx, state) => JobDetailScreen(jobId: int.parse(state.pathParameters['id']!))),
            GoRoute(path: '/jobs', builder: (_, __) => const JobsScreen()),
            GoRoute(path: '/processes', builder: (_, __) => const ProcessesScreen()),
            GoRoute(path: '/applications', builder: (_, __) => const ApplicationsScreen()),
            GoRoute(path: '/evaluations', builder: (_, __) => const EvaluationsScreen()),
            GoRoute(path: '/interviews', builder: (_, __) => const InterviewsScreen()),
            GoRoute(path: '/committees', builder: (_, __) => const CommitteesScreen()),
            GoRoute(path: '/results', builder: (_, __) => const ResultsScreen()),
            GoRoute(path: '/offers', builder: (_, __) => const OffersScreen()),
            GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
            GoRoute(path: '/users', builder: (_, __) => const UsersScreen()),
          ],
        );
        return MaterialApp.router(
          title: 'HR Recruitment',
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
          routerConfig: router,
        );
      }),
    );
  }
}

class RoleDashboard extends StatelessWidget {
  const RoleDashboard({super.key});
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
        _NavTile('Thiết lập quy trình', '/processes', Icons.account_tree),
        // Recruiter sẽ quản lý việc làm của mình tại cùng đường dẫn /jobs
        _NavTile(role=='recruiter' ? 'Việc làm của tôi' : 'Đăng tin tuyển dụng', '/jobs', Icons.work_outline),
        _NavTile('Sàng lọc/Đánh giá', '/evaluations', Icons.rate_review_outlined),
        _NavTile('Lịch phỏng vấn', '/interviews', Icons.event_outlined),
        if (role=='recruiter') _NavTile('Ứng viên của tôi', '/my-candidates', Icons.people_alt_outlined),
      ]);
    }
    if (role == 'admin') {
      tiles.addAll([
        _NavTile('Quản lý người dùng', '/users', Icons.manage_accounts_outlined),
        _NavTile('Hội đồng tuyển dụng', '/committees', Icons.group_work_outlined),
        _NavTile('Báo cáo', '/reports', Icons.pie_chart_outline),
      ]);
    }
    tiles.addAll([
      _NavTile(role=='recruiter' ? 'Việc làm của tôi' : 'Việc làm', '/jobs', Icons.work_history_outlined),
      if (role!='recruiter') _NavTile('Ứng tuyển của tôi', '/applications', Icons.assignment_outlined),
      _NavTile('Thư mời nhận việc', '/offers', Icons.mail_outline),
      _NavTile('Kết quả', '/results', Icons.verified_outlined),
    ]);
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [
        TextButton.icon(
          onPressed: ()=> context.read<AuthState>().logout(),
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text('Logout', style: TextStyle(color: Colors.white)),
        )
      ]),
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

// Below are simple placeholder screens; you can enhance with lists/forms calling APIs.
class JobsScreen extends StatefulWidget { const JobsScreen({super.key}); @override State<JobsScreen> createState()=> _JobsScreenState(); }
class _JobsScreenState extends State<JobsScreen>{
  int _tick=0;
  Future<List<dynamic>> _load(BuildContext c){
    final role = c.read<AuthState>().role;
    final params = <String,dynamic>{};
    if (role=='recruiter') params['mine']='true';
    return apiGetList('/jobs', params: params);
  }
  @override 
  Widget build(BuildContext c){
    final role = c.watch<AuthState>().role;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: Text(role=='recruiter' ? 'Việc làm của tôi' : 'Việc làm'),
      ),
      body: FutureBuilder<List<dynamic>>(
        key: ValueKey(_tick),
        future: _load(c),
        builder: (context, snap){
          if (snap.connectionState!=ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final items = (snap.data ?? []).cast<Map<String,dynamic>>();
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __)=> const Divider(height: 1),
            itemBuilder: (_, i){
              final j = items[i];
              return ListTile(
                title: Text(j['title']?.toString()??'Chưa đặt tiêu đề'),
                subtitle: Text(j['department']?.toString()??''),
                onTap: ()=> role=='candidate'? c.go('/jobs/${j['id']}') : null,
                trailing: (role=='admin' || role=='recruiter') ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Admin can always edit/delete; recruiter only on their own jobs (list already filtered when recruiter)
                    IconButton(icon: const Icon(Icons.edit), onPressed: ()=> _editJobDialog(c, j)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                      try{ await apiDelete('/jobs/${j['id']}'); setState(()=> _tick++);} catch(_){}}
                    ),
                  ],
                ) : null,
              );
            },
          );
        },
      ),
      floatingActionButton: (role=='admin' || role=='recruiter') ? FloatingActionButton(
        onPressed: ()=> _createJobDialog(c),
        child: const Icon(Icons.add),
      ) : null,
    );
  }
  Future<void> _createJobDialog(BuildContext c) async {
    final title=TextEditingController(); final dept=TextEditingController(); final loc=TextEditingController(); final desc=TextEditingController(); String? error;
    await showDialog(context:c, builder:(_)=> StatefulBuilder(builder:(context,setState){
      return AlertDialog(
        title: const Text('Đăng tin tuyển dụng'),
        content: SingleChildScrollView(child: Column(children:[
          TextField(controller: title, decoration: const InputDecoration(labelText:'Tiêu đề')), 
          TextField(controller: dept, decoration: const InputDecoration(labelText:'Phòng ban')),
          TextField(controller: loc, decoration: const InputDecoration(labelText:'Địa điểm')),
          TextField(controller: desc, maxLines: 4, decoration: const InputDecoration(labelText:'Mô tả công việc')),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async { try{
            await apiPost('/jobs', {'title': title.text, 'description': desc.text, 'department': dept.text.isEmpty? null:dept.text, 'location': loc.text.isEmpty? null:loc.text});
            if (context.mounted) Navigator.pop(context); setState(()=> _tick++);
          }catch(e){ setState(()=> error='Lưu thất bại'); }}, child: const Text('Lưu'))
        ],
      );
    }));
  }
  Future<void> _editJobDialog(BuildContext c, Map<String,dynamic> job) async {
    final title=TextEditingController(text: job['title']?.toString()??''); final dept=TextEditingController(text: job['department']?.toString()??''); final loc=TextEditingController(text: job['location']?.toString()??''); final desc=TextEditingController(text: job['description']?.toString()??''); String? error;
    await showDialog(context:c, builder:(_)=> StatefulBuilder(builder:(context,setState){
      return AlertDialog(
        title: const Text('Chỉnh sửa việc làm'),
        content: SingleChildScrollView(child: Column(children:[
          TextField(controller: title, decoration: const InputDecoration(labelText:'Tiêu đề')), 
          TextField(controller: dept, decoration: const InputDecoration(labelText:'Phòng ban')),
          TextField(controller: loc, decoration: const InputDecoration(labelText:'Địa điểm')),
          TextField(controller: desc, maxLines: 4, decoration: const InputDecoration(labelText:'Mô tả công việc')),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async { try{
            await apiPut('/jobs/${job['id']}', {'title': title.text, 'description': desc.text, 'department': dept.text.isEmpty? null:dept.text, 'location': loc.text.isEmpty? null:loc.text});
            if (context.mounted) Navigator.pop(context); setState(()=> _tick++);
          }catch(e){ setState(()=> error='Lưu thất bại'); }}, child: const Text('Lưu'))
        ],
      );
    }));
  }
}
class ProcessesScreen extends StatelessWidget { const ProcessesScreen({super.key}); @override Widget build(BuildContext c)=> _Scaffold(title:'Thiết lập quy trình'); }
class ApplicationsScreen extends StatelessWidget { 
  const ApplicationsScreen({super.key}); 
  @override 
  Widget build(BuildContext c){
    final role = c.watch<AuthState>().role;
    final params = <String,dynamic>{};
    if (role != 'admin') params['mine'] = 'true';
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')), title: const Text('Ứng tuyển của tôi')),
      body: FutureBuilder<List<dynamic>>(
        future: apiGetList('/applications', params: params),
        builder: (context, snap){
          if (snap.connectionState!=ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          var items = (snap.data ?? []).cast<Map<String,dynamic>>();
          // Chỉ hiển thị ứng tuyển đang active cho thí sinh (submitted/screening/interviewed/offered)
          if (role == 'candidate') {
            const active = {'submitted','screening','interviewed','offered'};
            items = items.where((a) => active.contains((a['status']??'').toString())).toList();
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __)=> const Divider(height: 1),
            itemBuilder: (_, i){
              final a = items[i];
              return ListTile(
                title: Text(a['full_name']?.toString()??'No name'),
                subtitle: Text('${a['email']??''} • Trạng thái: ${a['status']??''}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){},
        child: const Icon(Icons.person_add_alt),
      ),
    );
  }
}
class EvaluationsScreen extends StatelessWidget { const EvaluationsScreen({super.key}); @override Widget build(BuildContext c)=> _Scaffold(title:'Sàng lọc & Đánh giá'); }
class InterviewsScreen extends StatefulWidget { const InterviewsScreen({super.key}); @override State<InterviewsScreen> createState()=> _InterviewsScreenState(); }
class _InterviewsScreenState extends State<InterviewsScreen>{
  int _tick = 0;
  Future<List<dynamic>> _load(BuildContext c) => apiGetList('/interviews');
  @override
  Widget build(BuildContext c){
    final role = c.watch<AuthState>().role;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')), title: const Text('Lịch phỏng vấn')),
      body: FutureBuilder<List<dynamic>>(
        key: ValueKey(_tick),
        future: _load(c),
        builder: (context, snap){
          if (snap.connectionState!=ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final items = (snap.data ?? []).cast<Map<String,dynamic>>();
          if (items.isEmpty) return const Center(child: Text('Chưa có lịch phỏng vấn'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __)=> const Divider(height: 1),
            itemBuilder: (_, i){
              final itv = items[i];
              return ListTile(
                title: Text('Ứng tuyển #${itv['application_id']} • ${itv['scheduled_at']}'),
                subtitle: Text('${itv['location']??''} • ${itv['mode']??''} • Trạng thái: ${itv['status']??''}'),
                trailing: (role=='admin' || role=='recruiter') ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: ()=> _editInterviewDialog(context, itv)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { try{ await apiDelete('/interviews/${itv['id']}'); setState((){});} catch(_){}}),
                  ],
                ) : null,
              );
            },
          );
        },
      ),
      floatingActionButton: (role=='admin' || role=='recruiter') ? FloatingActionButton(
        onPressed: () async { await _createInterviewDialog(c); if (mounted) setState(()=> _tick++); }, child: const Icon(Icons.add),
      ) : null,
    );
  }
  Future<void> _createInterviewDialog(BuildContext c) async {
    Map<String,dynamic>? selectedApp; final loc=TextEditingController(); String? error;
    DateTime? scheduledAt; String mode='online';
    await showDialog(context:c, builder:(_)=> StatefulBuilder(builder: (context,setState){
      return AlertDialog(
        title: const Text('Tạo lịch phỏng vấn'),
        content: SingleChildScrollView(child: Column(children:[
          _AppPickerTile(
            selectedLabel: selectedApp==null? 'Chọn ứng tuyển' : '#${selectedApp!['id']} • ${selectedApp!['full_name']} • ${selectedApp!['email']}',
            onPick: () async {
              final picked = await showDialog<Map<String,dynamic>>(context: context, builder: (_) => const _ApplicationPickerDialog());
              if (picked!=null) setState(()=> selectedApp = picked);
            },
          ),
          Row(children:[
            Expanded(child: OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(context: context, initialDate: scheduledAt ?? now, firstDate: DateTime(now.year-3), lastDate: DateTime(now.year+3));
                if (d!=null){
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(scheduledAt ?? now));
                  final combined = DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0);
                  setState(()=> scheduledAt = combined);
                }
              },
              icon: const Icon(Icons.event),
              label: Text(scheduledAt==null? 'Chọn thời gian' : scheduledAt!.toIso8601String()),
            )),
          ]),
          TextField(controller: loc, decoration: const InputDecoration(labelText:'Địa điểm')),
          DropdownButtonFormField<String>(
            value: mode,
            decoration: const InputDecoration(labelText:'Hình thức'),
            items: const [
              DropdownMenuItem(value:'online', child: Text('online')),
              DropdownMenuItem(value:'offline', child: Text('offline')),
            ],
            onChanged: (v){ if (v!=null) setState(()=> mode=v); },
          ),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async { 
            try{
              if (selectedApp==null) { setState(()=> error='Vui lòng chọn ứng tuyển'); return; }
              final when = scheduledAt ?? DateTime.now();
              await apiPost('/interviews', {
                'application_id': selectedApp!['id'],
                'scheduled_at': when.toIso8601String(),
                'location': loc.text.trim().isEmpty? null:loc.text.trim(),
                'mode': mode,
              });
              if (context.mounted) Navigator.pop(context);
            }catch(e){ setState(()=> error='Lưu thất bại'); }
          }, child: const Text('Lưu'))
        ],
      );
    }));
  }
  Future<void> _editInterviewDialog(BuildContext c, Map<String,dynamic> itv) async {
    final loc=TextEditingController(text: itv['location']?.toString()??''); String? error;
    DateTime? scheduledAt = (){ try{ return DateTime.parse(itv['scheduled_at']?.toString()??''); } catch(_){ return null; } }();
    String mode = (itv['mode']?.toString()??'online');
    String status = (itv['status']?.toString() ?? 'scheduled');
    await showDialog(context:c, builder:(_)=> StatefulBuilder(builder: (context,setState){
      return AlertDialog(
        title: const Text('Cập nhật lịch phỏng vấn'),
        content: SingleChildScrollView(child: Column(children:[
          Row(children:[
            Expanded(child: OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(context: context, initialDate: scheduledAt ?? now, firstDate: DateTime(now.year-3), lastDate: DateTime(now.year+3));
                if (d!=null){
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(scheduledAt ?? now));
                  final combined = DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0);
                  setState(()=> scheduledAt = combined);
                }
              },
              icon: const Icon(Icons.event),
              label: Text(scheduledAt==null? 'Chọn thời gian' : scheduledAt!.toIso8601String()),
            )),
          ]),
          TextField(controller: loc, decoration: const InputDecoration(labelText:'Địa điểm')),
          DropdownButtonFormField<String>(
            value: mode,
            decoration: const InputDecoration(labelText:'Hình thức'),
            items: const [
              DropdownMenuItem(value:'online', child: Text('online')),
              DropdownMenuItem(value:'offline', child: Text('offline')),
            ],
            onChanged: (v){ if (v!=null) setState(()=> mode=v); },
          ),
          DropdownButtonFormField<String>(
            value: status,
            decoration: const InputDecoration(labelText:'Trạng thái'),
            items: const [
              DropdownMenuItem(value:'scheduled', child: Text('scheduled')),
              DropdownMenuItem(value:'completed', child: Text('completed')),
              DropdownMenuItem(value:'canceled', child: Text('canceled')),
              DropdownMenuItem(value:'no-show', child: Text('no-show')),
            ],
            onChanged: (v){ if (v!=null) setState(()=> status=v); },
          ),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async { try{
            await apiPut('/interviews/${itv['id']}', {
              'scheduled_at': scheduledAt==null? null : scheduledAt!.toIso8601String(),
              'location': loc.text.trim().isEmpty? null:loc.text.trim(),
              'mode': mode,
              'status': status,
            });
            if (context.mounted) { Navigator.pop(context); setState(()=> _tick++); }
          }catch(e){ setState(()=> error='Lưu thất bại'); }}, child: const Text('Lưu'))
        ],
      );
    }));
  }
}
class CommitteesScreen extends StatelessWidget { const CommitteesScreen({super.key}); @override Widget build(BuildContext c)=> _Scaffold(title:'Hội đồng tuyển dụng'); }
class ResultsScreen extends StatefulWidget { const ResultsScreen({super.key}); @override State<ResultsScreen> createState()=> _ResultsScreenState(); }
class _ResultsScreenState extends State<ResultsScreen>{
  final _search = TextEditingController();
  int? _selectedJobId;
  List<Map<String,dynamic>> _jobs = [];
  int _tick = 0;
  @override void initState(){ super.initState(); _loadJobs(); }
  Future<void> _loadJobs() async {
    final role = context.read<AuthState>().role;
    final params = role == 'admin' ? <String,dynamic>{} : {'mine':'true'};
    final list = await apiGetList('/jobs', params: params);
    setState(()=> _jobs = list.cast<Map<String,dynamic>>());
  }
  Map<String,dynamic> _buildParams(){
    final role = context.read<AuthState>().role;
    final p = <String,dynamic>{};
    if (role != 'admin') p['mine']='true';
    if (_selectedJobId != null) p['job_id'] = _selectedJobId;
    if (_search.text.isNotEmpty) p['q'] = _search.text;
    return p;
  }
  @override
  Widget build(BuildContext c){
    final role = c.watch<AuthState>().role;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')), title: const Text('Kết quả tuyển dụng')),
      body: Column(children: [
        if (role=='admin' || role=='recruiter') Padding(
          padding: const EdgeInsets.all(8.0), child: Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              value: _selectedJobId,
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('Tất cả công việc')),
                ..._jobs.map((j)=> DropdownMenuItem<int>(value: j['id'] as int, child: Text(j['title']?.toString()??'')))
              ],
              onChanged: (v){ setState(()=> _selectedJobId = v); },
              decoration: const InputDecoration(labelText: 'Lọc theo công việc'),
            )),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm theo tên/email'), onSubmitted: (_)=> setState((){})))
          ]),
        ),
        Expanded(child: FutureBuilder<List<dynamic>>(
          key: ValueKey(_tick),
          future: apiGetList('/results', params: _buildParams()),
          builder: (context, snap){
            if (snap.connectionState!=ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
            final items = (snap.data ?? []).cast<Map<String,dynamic>>();
            if (items.isEmpty) return const Center(child: Text('Chưa có kết quả'));
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __)=> const Divider(height: 1),
              itemBuilder: (_, i){
                final r = items[i];
                return ListTile(
                  title: Text('${r['result']??''} • ${r['job_title']??''}'),
                  subtitle: Text('${r['full_name']??''} • ${r['email']??''}\n${r['notes']?.toString() ?? ''}'),
                  trailing: (role=='admin' || role=='recruiter') ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () async { await _editResultDialog(context, r); if (mounted) setState(()=> _tick++); }),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                        try{ await apiDelete('/results/${r['id']}'); if (mounted) setState(()=> _tick++); } catch(_){ }
                      }),
                    ],
                  ) : null,
                );
              },
            );
          },
        ))
      ]),
      floatingActionButton: (role=='admin' || role=='recruiter') ? FloatingActionButton(
        onPressed: () async { await _createResultDialog(context); if (mounted) setState(()=> _tick++); }, child: const Icon(Icons.add),
      ) : null,
    );
  }
  Future<void> _createResultDialog(BuildContext c) async {
    Map<String,dynamic>? selectedApp;
    String resultValue = 'passed';
    final notesCtrl = TextEditingController();
    String? error;
    await showDialog(context: c, builder: (_) => StatefulBuilder(builder: (context, setState){
      return AlertDialog(
        title: const Text('Thêm kết quả'),
        content: SingleChildScrollView(child: Column(children: [
          _AppPickerTile(
            selectedLabel: selectedApp==null? 'Chọn ứng tuyển' : '#${selectedApp!['id']} • ${selectedApp!['full_name']} • ${selectedApp!['email']}',
            onPick: () async {
              final picked = await showDialog<Map<String,dynamic>>(context: context, builder: (_) => const _ApplicationPickerDialog());
              if (picked!=null) setState(()=> selectedApp = picked);
            },
          ),
          DropdownButtonFormField<String>(
            value: resultValue,
            decoration: const InputDecoration(labelText: 'Kết quả'),
            items: const [
              DropdownMenuItem(value:'passed', child: Text('passed')),
              DropdownMenuItem(value:'failed', child: Text('failed')),
              DropdownMenuItem(value:'rejected', child: Text('rejected')),
              DropdownMenuItem(value:'hired', child: Text('hired')),
              DropdownMenuItem(value:'offer', child: Text('offer')),
              DropdownMenuItem(value:'accepted', child: Text('accepted')),
            ],
            onChanged: (v){ if (v!=null) setState(()=> resultValue=v); },
          ),
          TextField(controller: notesCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Ghi chú')),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async {
            try{
              if (selectedApp==null) { setState(()=> error='Vui lòng chọn ứng tuyển'); return; }
              await apiPost('/results', {
                'application_id': selectedApp!['id'],
                'result': resultValue,
                'notes': notesCtrl.text.isEmpty? null : notesCtrl.text,
              });
              if (context.mounted) Navigator.pop(context);
            } catch(e){ setState(()=> error='Lưu thất bại'); }
          }, child: const Text('Lưu')),
        ],
      );
    }));
  }
  Future<void> _editResultDialog(BuildContext c, Map<String,dynamic> r) async {
    String resultValue = (r['result']?.toString() ?? 'passed');
    final notesCtrl = TextEditingController(text: r['notes']?.toString() ?? '');
    String? error;
    await showDialog(context: c, builder: (_) => StatefulBuilder(builder: (context, setState){
      return AlertDialog(
        title: const Text('Cập nhật kết quả'),
        content: SingleChildScrollView(child: Column(children: [
          DropdownButtonFormField<String>(
            value: resultValue,
            decoration: const InputDecoration(labelText: 'Kết quả'),
            items: const [
              DropdownMenuItem(value:'passed', child: Text('passed')),
              DropdownMenuItem(value:'failed', child: Text('failed')),
              DropdownMenuItem(value:'rejected', child: Text('rejected')),
              DropdownMenuItem(value:'hired', child: Text('hired')),
              DropdownMenuItem(value:'offer', child: Text('offer')),
              DropdownMenuItem(value:'accepted', child: Text('accepted')),
            ],
            onChanged: (v){ if (v!=null) setState(()=> resultValue=v); },
          ),
          TextField(controller: notesCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Ghi chú')),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async {
            try{
              await apiPut('/results/${r['id']}', {
                'result': resultValue,
                'notes': notesCtrl.text.isEmpty? null : notesCtrl.text,
              });
              if (context.mounted) Navigator.pop(context);
            } catch(e){ setState(()=> error='Lưu thất bại'); }
          }, child: const Text('Lưu')),
        ],
      );
    }));
  }
}
class OffersScreen extends StatefulWidget { const OffersScreen({super.key}); @override State<OffersScreen> createState()=> _OffersScreenState(); }
class _OffersScreenState extends State<OffersScreen>{
  Future<List<dynamic>> _load(BuildContext c){
    final role = c.read<AuthState>().role;
    return apiGetList('/offers', params: _buildParams(role));
  }
  final _search = TextEditingController();
  int? _selectedJobId;
  int? _selectedSenderId; // admin only
  List<Map<String,dynamic>> _jobs = [];
  List<Map<String,dynamic>> _senders = [];
  @override void initState(){ super.initState(); _loadJobs(); }
  Future<void> _loadJobs() async {
    final role = context.read<AuthState>().role;
    if (role=='admin' || role=='recruiter'){
      final params = role=='admin'? <String,dynamic>{} : {'mine':'true'};
      final list = await apiGetList('/jobs', params: params);
      setState(()=> _jobs = list.cast<Map<String,dynamic>>());
      if (role=='admin'){
        final users = await apiGetList('/users');
        // Filter to admins/recruiters for sender dropdown
        setState(()=> _senders = users.cast<Map<String,dynamic>>().where((u){
          final r = (u['role']??'').toString();
          return r=='admin' || r=='recruiter';
        }).toList());
      }
    }
  }
  Map<String,dynamic> _buildParams(String role){
    final m = <String,dynamic>{};
    if (role != 'admin') m['mine'] = 'true'; // recruiter: see offers sent by me or for my jobs; candidate: mine shows their own
    if (_selectedJobId != null) m['job_id'] = _selectedJobId;
    if (role=='admin' && _selectedSenderId != null) m['sender_id'] = _selectedSenderId;
    if (_search.text.isNotEmpty) m['q'] = _search.text;
    return m;
  }

  @override
  Widget build(BuildContext c){
    final role = c.watch<AuthState>().role;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')), title: const Text('Thư mời nhận việc')),
      body: FutureBuilder<List<dynamic>>(
        future: _load(c),
        builder: (context, snap){
          if (snap.connectionState!=ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Chưa có thư mời'));
          return Column(children: [
            if (role=='admin' || role=='recruiter') Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                Expanded(child: DropdownButtonFormField<int>(
                  value: _selectedJobId,
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('Tất cả công việc')),
                    ..._jobs.map((j)=> DropdownMenuItem<int>(value: j['id'] as int, child: Text(j['title']?.toString()??'')))
                  ],
                  onChanged: (v){ setState(()=> _selectedJobId = v); },
                  decoration: const InputDecoration(labelText: 'Lọc theo công việc'),
                )),
                if (role=='admin') const SizedBox(width: 8),
                if (role=='admin') Expanded(child: DropdownButtonFormField<int>(
                  value: _selectedSenderId,
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('Tất cả người gửi')),
                    ..._senders.map((u)=> DropdownMenuItem<int>(value: u['id'] as int, child: Text('${u['full_name']} (${u['email']})')))
                  ],
                  onChanged: (v){ setState(()=> _selectedSenderId = v); },
                  decoration: const InputDecoration(labelText: 'Lọc theo người gửi'),
                )),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm theo tên hoặc email'), onSubmitted: (_)=> setState((){}))),
              ]),
            ),
            Expanded(child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __)=> const Divider(height: 1),
            itemBuilder: (_, i){
              final o = items[i] as Map<String, dynamic>;
              return ListTile(
                title: Text('${o['position']??'Vị trí'} • ${o['start_date']??''}'),
                subtitle: Text('${o['full_name']??''} • ${o['email']??''} • ${o['job_title']??''}\nNgười gửi: ${o['sender_name']??'-'} • ${o['sender_email']??''}\nMức lương: ${o['salary']?.toString() ?? '-'}'),
                onTap: () => _viewOfferDialog(context, o),
                trailing: null,
              );
              },
            ))
          ]);
        },
      ),
      floatingActionButton: (role=='admin') ? FloatingActionButton(
        onPressed: ()=> _createOfferDialog(c),
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Future<void> _viewOfferDialog(BuildContext c, Map<String,dynamic> o) async {
    await showDialog(context: c, builder: (_) => AlertDialog(
      title: const Text('Chi tiết thư mời'),
      content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Vị trí: ${o['position']??''}'),
        Text('Ngày bắt đầu: ${o['start_date']??''}'),
        Text('Lương: ${o['salary']?.toString() ?? ''}'),
        const SizedBox(height: 12),
        Text(o['content']?.toString() ?? '(Không có nội dung)')
      ])),
      actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Đóng'))],
    ));
  }

  Future<void> _createOfferDialog(BuildContext c) async {
    await _offerFormDialog(c, null);
    if (mounted) setState((){});
  }

  // Offers are immutable; no edit dialog

  Future<void> _offerFormDialog(BuildContext c, Map<String,dynamic>? offer) async {
    Map<String,dynamic>? selectedApp;
    DateTime? startDate;
    final posCtrl = TextEditingController(text: offer?['position']?.toString() ?? '');
    final salaryCtrl = TextEditingController(text: offer?['salary']?.toString() ?? '');
    final contentCtrl = TextEditingController(text: offer?['content']?.toString() ?? '');
    String? error;
    await showDialog(context: c, builder: (_) => StatefulBuilder(builder: (context, setState){
      return AlertDialog(
        title: Text(offer==null? 'Tạo thư mời' : 'Cập nhật thư mời'),
        content: SingleChildScrollView(child: Column(children: [
          if (offer==null) _AppPickerTile(
            selectedLabel: selectedApp==null? 'Chọn ứng tuyển' : '#${selectedApp!['id']} • ${selectedApp!['full_name']} • ${selectedApp!['email']}',
            onPick: () async {
              final picked = await showDialog<Map<String,dynamic>>(context: context, builder: (_) => const _ApplicationPickerDialog());
              if (picked!=null) setState(()=> selectedApp = picked);
            },
          ), 
          Row(children:[
            Expanded(child: OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(context: context, initialDate: startDate ?? now, firstDate: DateTime(now.year-3), lastDate: DateTime(now.year+3));
                if (d!=null) setState(()=> startDate = d);
              },
              icon: const Icon(Icons.event),
              label: Text(startDate==null? 'Chọn ngày bắt đầu' : '${startDate!.year.toString().padLeft(4,'0')}-${startDate!.month.toString().padLeft(2,'0')}-${startDate!.day.toString().padLeft(2,'0')}'),
            ))
          ]),
          TextField(controller: posCtrl, decoration: const InputDecoration(labelText: 'Vị trí')),
          TextField(controller: salaryCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Lương')),
          TextField(controller: contentCtrl, maxLines: 6, decoration: const InputDecoration(labelText: 'Nội dung thư (HTML)')),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async {
            try{
              if (offer==null){
                if (selectedApp==null) { setState(()=> error='Vui lòng chọn ứng tuyển'); return; }
                final body = {
                  'application_id': selectedApp!['id'],
                  'start_date': startDate==null? '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2,'0')}-${DateTime.now().day.toString().padLeft(2,'0')}' : '${startDate!.year.toString().padLeft(4,'0')}-${startDate!.month.toString().padLeft(2,'0')}-${startDate!.day.toString().padLeft(2,'0')}',
                  'position': posCtrl.text.isEmpty? null : posCtrl.text,
                  'salary': salaryCtrl.text.isEmpty ? null : double.tryParse(salaryCtrl.text),
                  'content': contentCtrl.text.isEmpty? null : contentCtrl.text,
                };
                await apiPost('/offers', body);
              } else {
                final body = {
                  'start_date': startDate==null? null : '${startDate!.year.toString().padLeft(4,'0')}-${startDate!.month.toString().padLeft(2,'0')}-${startDate!.day.toString().padLeft(2,'0')}',
                  'position': posCtrl.text.isEmpty? null : posCtrl.text,
                  'salary': salaryCtrl.text.isEmpty? null : double.tryParse(salaryCtrl.text),
                  'content': contentCtrl.text.isEmpty? null : contentCtrl.text,
                };
                await apiPut('/offers/${offer['id']}', body);
              }
              if (context.mounted) Navigator.pop(context);
            } catch(e){ setState(()=> error='Lưu thất bại'); }
          }, child: const Text('Lưu')),
        ],
      );
    }));
    posCtrl.dispose(); salaryCtrl.dispose(); contentCtrl.dispose();
  }
}

class MyCandidatesScreen extends StatefulWidget { const MyCandidatesScreen({super.key}); @override State<MyCandidatesScreen> createState()=> _MyCandidatesScreenState(); }
class _MyCandidatesScreenState extends State<MyCandidatesScreen>{
  final _search = TextEditingController();
  int? _selectedJobId; List<Map<String,dynamic>> _jobs = [];
  @override void initState(){ super.initState(); _loadJobs(); }
  Future<void> _loadJobs() async {
    final list = await apiGetList('/jobs', params: {'mine':'true'});
    setState(()=> _jobs = list.cast<Map<String,dynamic>>());
  }
  Future<List<dynamic>> _load() async {
    final p = <String,dynamic>{'mine':'true'};
    if (_selectedJobId != null) p['job_id'] = _selectedJobId;
    if (_search.text.isNotEmpty) p['q'] = _search.text;
    return apiGetList('/applications', params: p);
  }
  @override
  Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')), title: const Text('Ứng viên của tôi')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              value: _selectedJobId,
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('Tất cả công việc')),
                ..._jobs.map((j)=> DropdownMenuItem<int>(value: j['id'] as int, child: Text(j['title']?.toString()??'')))
              ],
              onChanged: (v){ setState(()=> _selectedJobId = v); },
              decoration: const InputDecoration(labelText: 'Lọc theo công việc'),
            )),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm theo tên/email'), onSubmitted: (_)=> setState((){})))
          ]),
        ),
        Expanded(child: FutureBuilder<List<dynamic>>(
          future: _load(),
          builder: (context, snap){
            if (snap.connectionState!=ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
            final items = snap.data ?? [];
            if (items.isEmpty) return const Center(child: Text('Chưa có ứng viên'));
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __)=> const Divider(height: 1),
              itemBuilder: (_, i){
                final a = items[i] as Map<String, dynamic>;
                return ListTile(
                  title: Text(a['full_name']?.toString()??''),
                  subtitle: Text('${a['email']??''} • Trạng thái: ${a['status']??''}'),
                  trailing: IconButton(icon: const Icon(Icons.mail_outline), onPressed: ()=> _composeOfferFromApp(context, a)),
                );
              },
            );
          },
        ))
      ]),
    );
  }
  Future<void> _composeOfferFromApp(BuildContext c, Map<String,dynamic> app) async {
    final defaultHtml = 'Xin chào ${app['full_name']},<br/>Chúng tôi trân trọng mời bạn vào vị trí ...';
    final startCtrl = TextEditingController();
    final posCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    final contentCtrl = TextEditingController(text: defaultHtml);
    String? error;
    await showDialog(context: c, builder: (_) => StatefulBuilder(builder: (context, setState){
      return AlertDialog(
        title: Text('Gửi thư mời cho ${app['full_name']}'),
        content: SingleChildScrollView(child: Column(children: [
          TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Ngày bắt đầu (YYYY-MM-DD)')),
          TextField(controller: posCtrl, decoration: const InputDecoration(labelText: 'Vị trí')),
          TextField(controller: salaryCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Lương')),
          TextField(controller: contentCtrl, maxLines: 6, decoration: const InputDecoration(labelText: 'Nội dung thư (HTML)')),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async {
            try{
              final body = {
                'application_id': app['id'],
                'start_date': startCtrl.text,
                'position': posCtrl.text.isEmpty? null : posCtrl.text,
                'salary': salaryCtrl.text.isEmpty? null : double.tryParse(salaryCtrl.text),
                'content': contentCtrl.text.isEmpty? null : contentCtrl.text,
              };
              await apiPost('/offers', body);
              if (context.mounted) Navigator.pop(context);
            } catch(e){ setState(()=> error='Gửi thư thất bại'); }
          }, child: const Text('Gửi')),
        ],
      );
    }));
  }
}

// UI helper: tile to open the application picker
class _AppPickerTile extends StatelessWidget {
  final String selectedLabel; final VoidCallback onPick;
  const _AppPickerTile({required this.selectedLabel, required this.onPick});
  @override
  Widget build(BuildContext context){
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(selectedLabel),
      trailing: const Icon(Icons.search),
      onTap: onPick,
    );
  }
}

// Dialog: search and pick an application (id • name • email). Respects role scoping.
class _ApplicationPickerDialog extends StatefulWidget { const _ApplicationPickerDialog(); @override State<_ApplicationPickerDialog> createState()=> _ApplicationPickerDialogState(); }
class _ApplicationPickerDialogState extends State<_ApplicationPickerDialog>{
  final _search = TextEditingController();
  int? _selectedJobId; List<Map<String,dynamic>> _jobs = []; Future<List<dynamic>>? _future;
  @override void initState(){ super.initState(); _loadJobs(); _future = _fetch(); }
  Future<void> _loadJobs() async {
    final role = context.read<AuthState>().role;
    final params = role=='admin' ? <String,dynamic>{} : {'mine':'true'};
    final list = await apiGetList('/jobs', params: params);
    setState(()=> _jobs = list.cast<Map<String,dynamic>>());
  }
  Map<String,dynamic> _params(){
    final role = context.read<AuthState>().role;
    final p = <String,dynamic>{};
    if (role!='admin') p['mine']='true';
    if (_selectedJobId!=null) p['job_id'] = _selectedJobId;
    if (_search.text.isNotEmpty) p['q'] = _search.text;
    return p;
  }
  Future<List<dynamic>> _fetch() => apiGetList('/applications', params: _params());
  @override void dispose(){ _search.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context){
    return AlertDialog(
      title: const Text('Chọn ứng tuyển'),
      content: SizedBox(width: 520, child: Column(mainAxisSize: MainAxisSize.min, children:[
        Row(children:[
          Expanded(child: DropdownButtonFormField<int>(
            value: _selectedJobId,
            items: [
              const DropdownMenuItem<int>(value: null, child: Text('Tất cả công việc')),
              ..._jobs.map((j)=> DropdownMenuItem<int>(value: j['id'] as int, child: Text(j['title']?.toString()??'')))
            ],
            onChanged: (v){ setState(()=> _selectedJobId = v); _future = _fetch(); },
            decoration: const InputDecoration(labelText: 'Lọc theo công việc'),
          )),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm theo tên/email'), onSubmitted: (_){ setState(()=> _future=_fetch()); }))
        ]),
        const SizedBox(height: 8),
        SizedBox(height: 360, width: double.infinity, child: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snap){
            if (snap.connectionState!=ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
            final items = (snap.data ?? []).cast<Map<String,dynamic>>();
            if (items.isEmpty) return const Center(child: Text('Không có ứng tuyển'));
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __)=> const Divider(height: 1),
              itemBuilder: (_, i){
                final a = items[i];
                return ListTile(
                  title: Text('#${a['id']} • ${a['full_name']}'),
                  subtitle: Text('${a['email']} • Job #${a['job_id']}'),
                  onTap: ()=> Navigator.pop(context, a),
                );
              },
            );
          },
        )),
      ])),
      actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Đóng'))],
    );
  }
}

class JobDetailScreen extends StatefulWidget {
  final int jobId; const JobDetailScreen({super.key, required this.jobId});
  @override State<JobDetailScreen> createState()=> _JobDetailScreenState();
}
class _JobDetailScreenState extends State<JobDetailScreen>{
  Map<String,dynamic>? job; bool loading=true; String? error;
  final _name=TextEditingController();
  final _email=TextEditingController();
  final _phone=TextEditingController();
  final _resume=TextEditingController();
  final _cover=TextEditingController();
  @override void initState(){ super.initState(); _load(); }
  Future<void> _load() async {
    try{ job = await apiGet('/jobs/${widget.jobId}'); }
    catch(e){ error='Không tải được công việc'; }
    setState(()=> loading=false);
  }
  @override void dispose(){ _name.dispose(); _email.dispose(); _phone.dispose(); _resume.dispose(); _cover.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(title: Text(job!=null? job!['title']?.toString()??'Chi tiết công việc' : 'Chi tiết công việc')),
      body: loading? const Center(child: CircularProgressIndicator()) : error!=null? Center(child: Text(error!)) : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(job!['title']?.toString()??'', style: Theme.of(c).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(job!['description']?.toString()??''),
          const Divider(height: 32),
          Text('Nộp hồ sơ trực tuyến', style: Theme.of(c).textTheme.titleMedium),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Họ tên')),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Số điện thoại')),
          TextField(controller: _resume, decoration: const InputDecoration(labelText: 'Link CV (Drive, v.v.)')),
          TextField(controller: _cover, maxLines: 4, decoration: const InputDecoration(labelText: 'Thư ứng tuyển')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () async {
            try{
              final body = {
                'job_id': widget.jobId,
                'full_name': _name.text,
                'email': _email.text,
                'phone': _phone.text.isEmpty? null : _phone.text,
                'resume_url': _resume.text.isEmpty? null : _resume.text,
                'cover_letter': _cover.text.isEmpty? null : _cover.text,
              };
              await apiPost('/applications', body);
              if (context.mounted) ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Đã nộp hồ sơ')));
            }catch(e){ if (context.mounted) ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Nộp hồ sơ thất bại'))); }
          }, child: const Text('Nộp hồ sơ'))
        ]),
      ),
    );
  }
}
class ReportsScreen extends StatefulWidget { const ReportsScreen({super.key}); @override State<ReportsScreen> createState()=> _ReportsScreenState(); }
class _ReportsScreenState extends State<ReportsScreen>{
  DateTime? _from; DateTime? _to;

  Map<String,dynamic> _params(){
    final p = <String,dynamic>{};
    if (_from!=null) p['from'] = _fmtDate(_from!);
    if (_to!=null) p['to'] = _fmtDate(_to!);
    return p;
  }

  String _fmtDate(DateTime d){
    // Use YYYY-MM-DD format for server parsing
    return '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  Future<void> _pickFrom(BuildContext c) async {
    final now = DateTime.now();
    final picked = await showDatePicker(context:c, initialDate: _from ?? now, firstDate: DateTime(now.year-3), lastDate: DateTime(now.year+3));
    if (picked!=null) setState(()=> _from = picked);
  }
  Future<void> _pickTo(BuildContext c) async {
    final now = DateTime.now();
    final picked = await showDatePicker(context:c, initialDate: _to ?? now, firstDate: DateTime(now.year-3), lastDate: DateTime(now.year+3));
    if (picked!=null) setState(()=> _to = picked);
  }

  @override
  Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Báo cáo thống kê'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> setState((){})),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: ()=> _pickFrom(c), icon: const Icon(Icons.date_range), label: Text(_from==null? 'Từ ngày' : _fmtDate(_from!)))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: ()=> _pickTo(c), icon: const Icon(Icons.event), label: Text(_to==null? 'Đến ngày' : _fmtDate(_to!)))),
          ]),
          const SizedBox(height: 12),
          _SectionTitle('Tổng quan'),
          FutureBuilder<Map<String,dynamic>>(
            future: apiGet('/reports/summary', params: _params()),
            builder:(context,snap){
              if (snap.connectionState!=ConnectionState.done) return const _Loading();
              if (snap.hasError) return _Error(snap.error.toString());
              final s = snap.data ?? {};
              return Card(child: ListTile(
                title: Text('Ứng tuyển: ${s['totalApps']??0} • Thư mời: ${s['totalOffers']??0}'),
                subtitle: Text('Đậu: ${s['passed']??0} • Rớt: ${s['failed']??0} • Việc làm: ${s['totalJobs']??0}'),
              ));
            },
          ),
          const SizedBox(height: 12),
          _SectionTitle('Pipeline ứng tuyển'),
          FutureBuilder<List<dynamic>>(
            future: apiGetList('/reports/pipeline', params: _params()),
            builder:(context,snap){
              if (snap.connectionState!=ConnectionState.done) return const _Loading();
              if (snap.hasError) return _Error(snap.error.toString());
              final items = (snap.data ?? []).cast<Map<String,dynamic>>();
              if (items.isEmpty) return const _Empty('Không có dữ liệu pipeline');
              return Column(children: items.map((it)=> ListTile(
                title: Text('${it['status']??''}'),
                trailing: Text('${it['count']??0}'),
              )).toList());
            },
          ),
          const SizedBox(height: 12),
          _SectionTitle('Kết quả (đếm theo loại)'),
          FutureBuilder<List<dynamic>>(
            future: apiGetList('/reports/outcomes', params: _params()),
            builder:(context,snap){
              if (snap.connectionState!=ConnectionState.done) return const _Loading();
              if (snap.hasError) return _Error(snap.error.toString());
              final items = (snap.data ?? []).cast<Map<String,dynamic>>();
              if (items.isEmpty) return const _Empty('Không có dữ liệu kết quả');
              return Column(children: items.map((it)=> ListTile(
                title: Text('${it['result']??''}'),
                trailing: Text('${it['count']??0}'),
              )).toList());
            },
          ),
          const SizedBox(height: 12),
          _SectionTitle('Chi tiết kết quả'),
          FutureBuilder<List<dynamic>>(
            future: apiGetList('/reports/outcome-detail', params: _params()),
            builder:(context,snap){
              if (snap.connectionState!=ConnectionState.done) return const _Loading();
              if (snap.hasError) return _Error(snap.error.toString());
              final items = (snap.data ?? []).cast<Map<String,dynamic>>();
              if (items.isEmpty) return const _Empty('Không có kết quả');
              return Column(children: items.map((it)=> ListTile(
                title: Text('${it['result']??''} • ${it['job_title']??''}'),
                subtitle: Text('${it['full_name']??''} • ${it['email']??''}\n${it['notes']??''} • ${it['created_at']??''}'),
              )).toList());
            },
          ),
        ]),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget{ final String t; const _SectionTitle(this.t); @override Widget build(BuildContext c)=> Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(t, style: Theme.of(c).textTheme.titleMedium)); }
class _Loading extends StatelessWidget{ const _Loading(); @override Widget build(BuildContext c)=> const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())) ; }
class _Empty extends StatelessWidget{ final String t; const _Empty(this.t); @override Widget build(BuildContext c)=> Padding(padding: const EdgeInsets.all(8), child: Text(t)); }
class _Error extends StatelessWidget{ final String t; const _Error(this.t); @override Widget build(BuildContext c)=> Padding(padding: const EdgeInsets.all(8), child: Text('Lỗi: $t', style: const TextStyle(color: Colors.red))); }

class _Scaffold extends StatelessWidget {
  final String title;
  const _Scaffold({required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> context.go('/')), actions: [
        IconButton(icon: const Icon(Icons.home), onPressed: ()=> context.go('/')),
        IconButton(icon: const Icon(Icons.logout), onPressed: ()=> context.read<AuthState>().logout())
      ]),
      body: Center(
        child: Text('$title - TODO: build UI and call backend APIs'),
      ),
    );
  }
}

// Admin: User management
class UsersScreen extends StatefulWidget { const UsersScreen({super.key}); @override State<UsersScreen> createState()=> _UsersScreenState(); }
class _UsersScreenState extends State<UsersScreen>{
  int _tick=0; final _search = TextEditingController();
  Future<List<dynamic>> _load() => apiGetList('/users', params: _search.text.isEmpty? {} : {'q': _search.text});
  @override void dispose(){ _search.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')), title: const Text('Quản lý người dùng')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm theo tên/email'), onSubmitted: (_)=> setState(()=> _tick++)),
        ),
        Expanded(child: FutureBuilder<List<dynamic>>(
          key: ValueKey(_tick),
          future: _load(),
          builder: (context, snap){
            if (snap.connectionState!=ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
            final items = (snap.data ?? []).cast<Map<String,dynamic>>();
            if (items.isEmpty) return const Center(child: Text('Chưa có người dùng'));
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __)=> const Divider(height: 1),
              itemBuilder: (_, i){
                final u = items[i];
                return ListTile(
                  title: Text('${u['full_name']??''} • ${u['role']??''}'),
                  subtitle: Text(u['email']?.toString()??''),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.key_outlined), tooltip:'Đặt lại mật khẩu', onPressed: ()=> _resetPwdDialog(context, u)),
                    IconButton(icon: const Icon(Icons.edit), onPressed: ()=> _editUserDialog(context, u)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { try{ await apiDelete('/users/${u['id']}'); setState(()=> _tick++);} catch(_){}}),
                  ]),
                );
              },
            );
          },
        ))
      ]),
      floatingActionButton: FloatingActionButton(onPressed: ()=> _createUserDialog(context), child: const Icon(Icons.add)),
    );
  }

  Future<void> _createUserDialog(BuildContext c) async {
    final name=TextEditingController(); final email=TextEditingController(); final pwd=TextEditingController(); String? error;
    String role='candidate';
    await showDialog(context:c, builder:(_)=> StatefulBuilder(builder:(context,setState){
      return AlertDialog(
        title: const Text('Tạo người dùng'),
        content: SingleChildScrollView(child: Column(children:[
          TextField(controller: name, decoration: const InputDecoration(labelText:'Họ tên')),
          TextField(controller: email, decoration: const InputDecoration(labelText:'Email')),
          DropdownButtonFormField<String>(
            value: role,
            decoration: const InputDecoration(labelText:'Vai trò'),
            items: const [
              DropdownMenuItem(value:'admin', child: Text('admin')),
              DropdownMenuItem(value:'recruiter', child: Text('recruiter')),
              DropdownMenuItem(value:'candidate', child: Text('candidate')),
            ],
            onChanged: (v){ if (v!=null) setState(()=> role=v); },
          ),
          TextField(controller: pwd, decoration: const InputDecoration(labelText:'Mật khẩu (>=6 ký tự)'), obscureText: true),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async { try{
            await apiPost('/users', {'full_name': name.text, 'email': email.text, 'role': role, 'password': pwd.text});
            if (context.mounted) Navigator.pop(context); setState(()=> _tick++);
          }catch(e){ setState(()=> error='Lưu thất bại'); }}, child: const Text('Lưu'))
        ],
      );
    }));
  }

  Future<void> _editUserDialog(BuildContext c, Map<String,dynamic> u) async {
    final name=TextEditingController(text: u['full_name']?.toString()??''); final email=TextEditingController(text: u['email']?.toString()??''); String role=(u['role']?.toString()??'candidate'); final pwd=TextEditingController(); String? error;
    await showDialog(context:c, builder:(_)=> StatefulBuilder(builder:(context,setState){
      return AlertDialog(
        title: const Text('Cập nhật người dùng'),
        content: SingleChildScrollView(child: Column(children:[
          TextField(controller: name, decoration: const InputDecoration(labelText:'Họ tên')),
          TextField(controller: email, decoration: const InputDecoration(labelText:'Email')),
          DropdownButtonFormField<String>(
            value: role,
            decoration: const InputDecoration(labelText:'Vai trò'),
            items: const [
              DropdownMenuItem(value:'admin', child: Text('admin')),
              DropdownMenuItem(value:'recruiter', child: Text('recruiter')),
              DropdownMenuItem(value:'candidate', child: Text('candidate')),
            ],
            onChanged: (v){ if (v!=null) setState(()=> role=v); },
          ),
          TextField(controller: pwd, decoration: const InputDecoration(labelText:'Mật khẩu mới (tùy chọn)'), obscureText: true),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async { try{
            final body = {
              'full_name': name.text,
              'email': email.text,
              'role': role,
              if (pwd.text.isNotEmpty) 'password': pwd.text,
            };
            await apiPut('/users/${u['id']}', body);
            if (context.mounted) Navigator.pop(context); setState(()=> _tick++);
          }catch(e){ setState(()=> error='Lưu thất bại'); }}, child: const Text('Lưu'))
        ],
      );
    }));
  }

  Future<void> _resetPwdDialog(BuildContext c, Map<String,dynamic> u) async {
    final pwd=TextEditingController(); String? error;
    await showDialog(context:c, builder:(_)=> StatefulBuilder(builder:(context,setState){
      return AlertDialog(
        title: Text('Đặt lại mật khẩu • ${u['full_name']}'),
        content: Column(mainAxisSize: MainAxisSize.min, children:[
          TextField(controller: pwd, decoration: const InputDecoration(labelText:'Mật khẩu mới (>=6 ký tự)'), obscureText: true),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ]),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async { try{
            await apiPost('/users/${u['id']}/reset-password', {'password': pwd.text});
            if (context.mounted) Navigator.pop(context);
          }catch(e){ setState(()=> error='Thất bại'); }}, child: const Text('Cập nhật'))
        ],
      );
    }));
  }
}

class LoginScreen extends StatefulWidget { const LoginScreen({super.key}); @override State<LoginScreen> createState()=> _LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen>{
  final _email=TextEditingController();
  final _password=TextEditingController();
  String? error; bool busy=false;
  @override void dispose(){ _email.dispose(); _password.dispose(); super.dispose(); }
  @override Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _email, decoration: const InputDecoration(labelText:'Email')),
          TextField(controller: _password, decoration: const InputDecoration(labelText:'Mật khẩu'), obscureText: true),
          const SizedBox(height: 12),
          if (error!=null) Text(error!, style: const TextStyle(color: Colors.red)),
          ElevatedButton(
            onPressed: busy? null : () async {
              setState(()=>busy=true); error=null;
              try{ await context.read<AuthState>().login(_email.text, _password.text); context.go('/'); }
              catch(e){ setState(()=> error='Đăng nhập thất bại'); }
              finally{ setState(()=>busy=false); }
            },
            child: const Text('Đăng nhập'),
          ),
          TextButton(onPressed: ()=> context.go('/signup'), child: const Text('Chưa có tài khoản? Đăng ký'))
        ]),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget { const SignupScreen({super.key}); @override State<SignupScreen> createState()=> _SignupScreenState(); }
class _SignupScreenState extends State<SignupScreen>{
  final _name=TextEditingController();
  final _email=TextEditingController();
  final _password=TextEditingController();
  String? error; bool busy=false;
  @override void dispose(){ _name.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }
  @override Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký thí sinh')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText:'Họ tên')),
          TextField(controller: _email, decoration: const InputDecoration(labelText:'Email')),
          TextField(controller: _password, decoration: const InputDecoration(labelText:'Mật khẩu'), obscureText: true),
          const SizedBox(height: 12),
          if (error!=null) Text(error!, style: const TextStyle(color: Colors.red)),
          ElevatedButton(
            onPressed: busy? null : () async {
              setState(()=>busy=true); error=null;
              try{ await context.read<AuthState>().signup(_name.text, _email.text, _password.text); context.go('/'); }
              catch(e){ setState(()=> error='Đăng ký thất bại'); }
              finally{ setState(()=>busy=false); }
            },
            child: const Text('Đăng ký'),
          )
        ]),
      ),
    );
  }
}
