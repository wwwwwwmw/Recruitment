import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            GoRoute(path: '/my-profile', builder: (_, __) => const MyProfileScreen()),
            GoRoute(path: '/criteria', builder: (_, __) => const CriteriaAdminScreen()),
            GoRoute(path: '/my-candidates', builder: (_, __) => const MyCandidatesScreen()),
            GoRoute(path: '/jobs/:id', builder: (ctx, state) => JobDetailScreen(jobId: int.parse(state.pathParameters['id']!))),
            GoRoute(path: '/jobs', builder: (_, __) => const JobsScreen()),
            GoRoute(path: '/my-jobs', builder: (_, __) => const JobsScreen(mine: true)),
            GoRoute(path: '/processes', builder: (_, __) => const ProcessesScreen()),
            GoRoute(path: '/applications', builder: (_, __) => const ApplicationsScreen()),
            GoRoute(path: '/applications/:id', builder: (ctx, state) => ApplicationDetailScreen(
              appId: int.parse(state.pathParameters['id']!),
              initialScores: state.extra is Map<String,dynamic> ? state.extra as Map<String,dynamic> : null,
            )),
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
        // Tin tuyển dụng: xem tất cả jobs
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
      _NavTile(role=='recruiter' ? 'Việc làm của tôi' : 'Việc làm', role=='recruiter'? '/my-jobs' : '/jobs', Icons.work_history_outlined),
      if (role=='recruiter') _NavTile('Ứng viên của tôi', '/my-candidates', Icons.people_outline),
      if (role!='recruiter') _NavTile('Ứng tuyển của tôi', '/applications', Icons.assignment_outlined),
      if (role=='candidate') _NavTile('Hồ sơ của tôi', '/my-profile', Icons.badge_outlined),
      _NavTile('Thông báo', '/offers', Icons.mail_outline),
      _NavTile('Kết quả', '/results', Icons.verified_outlined),
    ]);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton.icon(
            onPressed: ()=> context.read<AuthState>().logout(),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Logout', style: TextStyle(color: Colors.white)),
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

// Below are simple placeholder screens; you can enhance with lists/forms calling APIs.
class CriteriaDef { final String key; final String label; final double min; final double max; final double step; const CriteriaDef(this.key,this.label,{required this.min, required this.max, this.step=1}); }

Future<List<CriteriaDef>> fetchCriteria() async {
  final list = await apiGetList('/criteria');
  if (list.isEmpty) return const [];
  return list.map((e){
    return CriteriaDef(
      (e['key']??'').toString(),
      (e['label']??'').toString(),
      min: (double.tryParse('${e['min']}') ?? 0),
      max: (double.tryParse('${e['max']}') ?? 100),
      step: (double.tryParse('${e['step']}') ?? 1),
    );
  }).cast<CriteriaDef>().toList();
}

class MyProfileScreen extends StatefulWidget { const MyProfileScreen({super.key}); @override State<MyProfileScreen> createState()=> _MyProfileScreenState(); }
class _MyProfileScreenState extends State<MyProfileScreen>{
  List<CriteriaDef> _criteria = const [];
  final Map<String, TextEditingController> _ctrl = {};
  final _extra = TextEditingController(); bool _busy=false; String? _error; List<Map<String,String>> _certs=[];
  @override void dispose(){ for(final c in _ctrl.values){ c.dispose(); } _extra.dispose(); super.dispose(); }
  Future<void> _load() async {
    try{
      final me = await apiGet('/profiles/me');
      final crit = await fetchCriteria();
      setState(()=> _criteria = crit);
      for (final c in crit){ _ctrl[c.key] = TextEditingController(); }
      final scores = (me['scores'] ?? {}) as Map<String,dynamic>;
      for(final c in crit){ final v = scores[c.key]; if (v!=null) _ctrl[c.key]!.text = v.toString(); }
      final extra = (me['extra'] ?? {})['notes']?.toString() ?? '';
      _extra.text = extra;
      final certs = (me['extra'] ?? {})['certificates'];
      if (certs is List){
        _certs = certs.map((e)=>{
          'type': (e['type']??'').toString(),
          'name': (e['name']??'').toString(),
          'url': (e['url']??'').toString(),
        }).toList();
      }
    }catch(_){ /* ignore */ }
  }
  @override void initState(){ super.initState(); _load(); }
  @override Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Hồ sơ của tôi'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          ..._criteria.map((cd){
            return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: TextField(
              controller: _ctrl[cd.key], keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '${cd.label}'),
            ));
          }),
          TextField(controller: _extra, maxLines: 4, decoration: const InputDecoration(labelText: 'Thông tin thêm (tuỳ chọn)')),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: Text('Chứng chỉ & Minh chứng', style: Theme.of(c).textTheme.titleSmall)),
          ..._certs.asMap().entries.map((e){ final i=e.key; final item=e.value; return Row(children:[
            SizedBox(width: 120, child: TextField(controller: TextEditingController(text:item['type']), decoration: const InputDecoration(hintText:'Loại (IELTS, ...)'), onChanged:(v)=> _certs[i]['type']=v)),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: TextEditingController(text:item['name']), decoration: const InputDecoration(hintText:'Tên chứng chỉ'), onChanged:(v)=> _certs[i]['name']=v)),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: TextEditingController(text:item['url']), decoration: const InputDecoration(hintText:'Liên kết minh chứng'), onChanged:(v)=> _certs[i]['url']=v)),
            IconButton(icon: const Icon(Icons.close), onPressed: ()=> setState(()=> _certs.removeAt(i)))
          ]); }),
          Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: ()=> setState(()=> _certs.add({'type':'','name':'','url':''})), icon: const Icon(Icons.add), label: const Text('Thêm chứng chỉ'))),
          if (_error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _busy? null : () async {
            setState((){ _busy=true; _error=null; });
            try{
              final scores = <String,double>{};
              for(final cd in _criteria){ final t = (_ctrl[cd.key]?.text ?? '').trim(); if (t.isNotEmpty){ final v = double.tryParse(t); if (v!=null) scores[cd.key]=v; } }
              final body = { 'scores': scores, 'extra': { 'notes': _extra.text.trim().isEmpty? null : _extra.text.trim(), 'certificates': _certs } };
              await apiPut('/profiles/me', body);
              if (mounted) ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Đã lưu hồ sơ')));
            }catch(e){ setState(()=> _error='Lưu thất bại'); }
            finally{ if (mounted) setState(()=> _busy=false); }
          }, child: const Text('Lưu hồ sơ')),
        ]),
      ),
    );
  }
}
class JobsScreen extends StatefulWidget {
  final bool mine; const JobsScreen({super.key, this.mine=false});
  @override State<JobsScreen> createState()=> _JobsScreenState();
}
class _JobsScreenState extends State<JobsScreen>{
  int _tick=0; final _search = TextEditingController();
  Future<List<dynamic>> _load(BuildContext c){
    final params = <String,dynamic>{};
    if (widget.mine) params['mine']='true';
    if (_search.text.isNotEmpty) params['q'] = _search.text;
    return apiGetList('/jobs', params: params);
  }
  @override 
  Widget build(BuildContext c){
    final role = c.watch<AuthState>().role; final meId = c.watch<AuthState>().user?['id'];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: Text(widget.mine? 'Việc làm của tôi' : 'Việc làm'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> setState(()=> _tick++))]
      ),
      body: Column(children:[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm theo tiêu đề/phòng ban/địa điểm'),
            onSubmitted: (_)=> setState(()=> _tick++),
          ),
        ),
        Expanded(child: FutureBuilder<List<dynamic>>(
          key: ValueKey(_tick),
          future: _load(c),
          builder: (context, snap){
          if (snap.connectionState!=ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          var items = (snap.data ?? []).cast<Map<String,dynamic>>();
          // Hide closed jobs from the public list for candidates
          if (role=='candidate' && !widget.mine){
            items = items.where((j)=> (j['status']?.toString() ?? '') != 'closed').toList();
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __)=> const Divider(height: 1),
            itemBuilder: (_, i){
              final j = items[i];
              return ListTile(
                title: Text(j['title']?.toString()??'Chưa đặt tiêu đề'),
                subtitle: Text('${j['department']??''}${(j['status']!=null)? ' • Trạng thái: ${j['status']}' : ''}'),
                onTap: ()=> role=='candidate'? c.go('/jobs/${j['id']}') : null,
                trailing: (role=='admin' || role=='recruiter') ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (role=='admin' || (role=='recruiter' && j['posted_by']==meId))
                      IconButton(icon: const Icon(Icons.edit), onPressed: ()=> _editJobDialog(c, j)),
                    if ((role=='admin' || (role=='recruiter' && j['posted_by']==meId)) && (j['status']?.toString()!='closed'))
                      IconButton(icon: const Icon(Icons.flag_outlined), tooltip: 'Kết thúc tuyển dụng', onPressed: () async { try{ await apiPost('/jobs/${j['id']}/close', {}); if (mounted) setState(()=> _tick++); } catch(_){ } }),
                    if (role=='admin' || (role=='recruiter' && j['posted_by']==meId))
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          try { await apiDelete('/jobs/${j['id']}'); setState(()=> _tick++); } catch(_){}
                        },
                      ),
                  ],
                ) : null,
              );
            },
          );
        },
      ))
      ],
      ),
      floatingActionButton: (role=='admin' || role=='recruiter') ? FloatingActionButton(
        onPressed: () async { final changed = await _createJobDialog(c); if (changed==true && mounted) setState(()=> _tick++); },
        child: const Icon(Icons.add),
      ) : null,
    );
  }
  Future<bool?> _createJobDialog(BuildContext c) async {
    final title=TextEditingController(); final dept=TextEditingController(); final loc=TextEditingController(); final desc=TextEditingController(); String? error;
    final criteria = await fetchCriteria();
    final Map<String, Map<String,dynamic>> reqs = { for(final cd in criteria) cd.key: { 'important': false, 'min': null } };
    bool changed = false;
    await showDialog(context:c, builder:(_)=> StatefulBuilder(builder:(context,setState){
      return AlertDialog(
        title: const Text('Đăng tin tuyển dụng'),
        content: SingleChildScrollView(child: Column(children:[
          TextField(controller: title, decoration: const InputDecoration(labelText:'Tiêu đề')), 
          TextField(controller: dept, decoration: const InputDecoration(labelText:'Phòng ban')),
          TextField(controller: loc, decoration: const InputDecoration(labelText:'Địa điểm')),
          TextField(controller: desc, maxLines: 4, decoration: const InputDecoration(labelText:'Mô tả công việc')),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: Text('Yêu cầu điểm', style: Theme.of(context).textTheme.titleSmall)),
          const SizedBox(height: 4),
          ...criteria.map((cd){
            final cfg = reqs[cd.key]!;
            return Row(children:[
              Expanded(child: Text(cd.label)),
              Checkbox(value: (cfg['important'] as bool), onChanged: (v){ setState(()=> cfg['important'] = v==true); }),
              SizedBox(width: 80, child: TextField(
                decoration: const InputDecoration(hintText: 'min'), keyboardType: TextInputType.number,
                onChanged: (t){ cfg['min'] = (t.trim().isEmpty? null : double.tryParse(t)); },
              )),
            ]);
          }),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async { try{
            final scores = <String,dynamic>{};
            reqs.forEach((k,v){ if (v['min']!=null) scores[k] = { 'min': v['min'], 'important': v['important']==true }; });
            final requirements = scores.isEmpty? null : { 'scores': scores };
            await apiPost('/jobs', {'title': title.text, 'description': desc.text, 'department': dept.text.isEmpty? null:dept.text, 'location': loc.text.isEmpty? null:loc.text, 'requirements': requirements});
            changed = true; if (context.mounted) Navigator.pop(context);
          }catch(e){ setState(()=> error='Lưu thất bại'); }}, child: const Text('Lưu'))
        ],
      );
    }));
    return changed;
  }
  Future<void> _editJobDialog(BuildContext c, Map<String,dynamic> job) async {
    final title=TextEditingController(text: job['title']?.toString()??''); final dept=TextEditingController(text: job['department']?.toString()??''); final loc=TextEditingController(text: job['location']?.toString()??''); final desc=TextEditingController(text: job['description']?.toString()??''); String? error;
    final criteria = await fetchCriteria();
    final existing = (job['requirements']?['scores'] ?? {}) as Map<String,dynamic>;
    final Map<String, Map<String,dynamic>> reqs = { for(final cd in criteria) cd.key: { 'important': (existing[cd.key]?['important']??false) == true, 'min': (existing[cd.key]?['min']) } };
    bool changed = false;
    await showDialog(context:c, builder:(_)=> StatefulBuilder(builder:(context,setState){
      return AlertDialog(
        title: const Text('Chỉnh sửa việc làm'),
        content: SingleChildScrollView(child: Column(children:[
          TextField(controller: title, decoration: const InputDecoration(labelText:'Tiêu đề')), 
          TextField(controller: dept, decoration: const InputDecoration(labelText:'Phòng ban')),
          TextField(controller: loc, decoration: const InputDecoration(labelText:'Địa điểm')),
          TextField(controller: desc, maxLines: 4, decoration: const InputDecoration(labelText:'Mô tả công việc')),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: Text('Yêu cầu điểm', style: Theme.of(context).textTheme.titleSmall)),
          const SizedBox(height: 4),
          ...criteria.map((cd){
            final cfg = reqs[cd.key]!;
            return Row(children:[
              Expanded(child: Text(cd.label)),
              Checkbox(value: (cfg['important'] as bool), onChanged: (v){ setState(()=> cfg['important'] = v==true); }),
              SizedBox(width: 80, child: TextField(
                controller: TextEditingController(text: (cfg['min']?.toString() ?? '')), keyboardType: TextInputType.number,
                onChanged: (t){ cfg['min'] = (t.trim().isEmpty? null : double.tryParse(t)); },
              )),
            ]);
          }),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async { try{
            final scores = <String,dynamic>{}; reqs.forEach((k,v){ if (v['min']!=null) scores[k] = { 'min': v['min'], 'important': v['important']==true }; });
            final requirements = scores.isEmpty? null : { 'scores': scores };
            await apiPut('/jobs/${job['id']}', {'title': title.text, 'description': desc.text, 'department': dept.text.isEmpty? null:dept.text, 'location': loc.text.isEmpty? null:loc.text, 'requirements': requirements});
            changed = true; if (context.mounted) Navigator.pop(context);
          }catch(e){ setState(()=> error='Lưu thất bại'); }}, child: const Text('Lưu'))
        ],
      );
    }));
    if (changed && mounted) setState(()=> _tick++);
  }
}
class ProcessesScreen extends StatelessWidget {
  const ProcessesScreen({super.key});
  @override
  Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Thiết lập quy trình'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> c.go('/processes'))],
      ),
      body: const Center(child: Text('Thiết lập quy trình - TODO xây UI và API')),
    );
  }
}
class ApplicationsScreen extends StatefulWidget { const ApplicationsScreen({super.key}); @override State<ApplicationsScreen> createState()=> _ApplicationsScreenState(); }
class _ApplicationsScreenState extends State<ApplicationsScreen>{
  int _tick=0;
  @override 
  Widget build(BuildContext c){
    final role = c.watch<AuthState>().role;
    final params = <String,dynamic>{};
    if (role != 'admin') params['mine'] = 'true';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Ứng tuyển của tôi'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> setState(()=> _tick++))],
      ),
      body: FutureBuilder<List<dynamic>>(
        key: ValueKey(_tick),
        future: apiGetList('/applications', params: params),
        builder: (context, snap){
          if (snap.connectionState!=ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          var items = (snap.data ?? []).cast<Map<String,dynamic>>();
          if (role == 'candidate') {
            // Show all, including rejected/offer for candidate history
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __)=> const Divider(height: 1),
            itemBuilder: (_, i){
              final a = items[i];
              return ListTile(
                title: Text(a['job_title']?.toString()??'Công việc #${a['job_id']}'),
                subtitle: Text('${a['full_name']??''} • ${a['email']??''} • Trạng thái: ${a['status']??''}'),
                onTap: role=='candidate' ? ()=> c.go('/applications/${a['id']}') : null,
              );
            },
          );
        },
      ),
    );
  }
}
// class EvaluationsScreen placeholder removed; see stateful implementation below
class EvaluationsScreen extends StatefulWidget { const EvaluationsScreen({super.key}); @override State<EvaluationsScreen> createState()=> _EvaluationsScreenState(); }
class _EvaluationsScreenState extends State<EvaluationsScreen>{
  int _tick=0; int? _selectedJobId; List<Map<String,dynamic>> _jobs=[]; List<Map<String,dynamic>> _results=[]; Map<String,dynamic>? _job; int _minPercent=0;
  @override void initState(){ super.initState(); _loadJobs(); }
  Future<void> _loadJobs() async {
    final role = context.read<AuthState>().role; final params = role=='admin'? <String,dynamic>{} : {'mine':'true'};
    final list = await apiGetList('/jobs', params: params);
    setState(()=> _jobs = list.cast<Map<String,dynamic>>());
  }
  Future<void> _runScreening() async {
    if (_selectedJobId==null) return;
    final data = await apiGet('/evaluations/screening', params: {'job_id': _selectedJobId});
    setState((){ _job = data['job'] as Map<String,dynamic>?; _results = (data['results']??[]).cast<Map<String,dynamic>>(); _tick++; });
  }
  int _calcPercent(Map<String,dynamic> r){
    // Prefer server-provided percent if present
    final p = r['percent'];
    if (p is num) return p.toInt();
    // Compute from candidate scores vs job requirements safely
    final reqDyn = _job?['requirements']?['scores'];
  final Map<String,dynamic> req = (reqDyn is Map) ? Map<String,dynamic>.from(reqDyn) : <String,dynamic>{};
    if (req.isEmpty) return 0;
    final scoresDyn = r['scores'];
  final Map<String,dynamic> scores = (scoresDyn is Map) ? Map<String,dynamic>.from(scoresDyn) : <String,dynamic>{};
    double sum = 0; int count = 0;
    req.forEach((key, cfg){
      final min = (cfg is Map && cfg['min'] is num) ? (cfg['min'] as num).toDouble() : null;
      if (min == null || min <= 0) return;
      final v = (scores[key] is num) ? (scores[key] as num).toDouble() : double.tryParse('${scores[key]??''}') ?? 0.0;
      final ratio = (v <= 0) ? 0.0 : (v / min);
      sum += ratio; // average of ratios as requested
      count += 1;
    });
    if (count == 0) return 0;
    return ((sum / count) * 100).round();
  }
  Future<void> _sendOfferFromResult(BuildContext c, Map<String,dynamic> r) async {
    Map<String,dynamic>? app;
    try{
      final list = await apiGetList('/applications', params: {
        if (_selectedJobId!=null) 'job_id': _selectedJobId,
        'q': (r['email']??'').toString(),
      });
      if (list.isNotEmpty) app = (list.first as Map<String,dynamic>);
    }catch(_){ }
    if (app==null){
      app = await showDialog<Map<String,dynamic>>(context: c, builder: (_)=> const _ApplicationPickerDialog());
      if (app==null) return;
    }
    // Compose and send offer similar to MyCandidates
  final defaultHtml = 'Xin chào ${app['full_name']},<br/>Thông báo từ bộ phận tuyển dụng...';
    DateTime? startDate;
    final posCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    final contentCtrl = TextEditingController(text: defaultHtml);
    String? error;
    await showDialog(context: c, builder: (_) => StatefulBuilder(builder: (context, setState){
      return AlertDialog(
        title: Text('Gửi thông báo cho ${app!['full_name']}'),
        content: SingleChildScrollView(child: Column(children: [
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
          TextField(controller: contentCtrl, maxLines: 6, decoration: const InputDecoration(labelText: 'Nội dung thông báo (HTML)')),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async {
            try{
              final body = {
                'application_id': app!['id'],
                'start_date': startDate==null? '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2,'0')}-${DateTime.now().day.toString().padLeft(2,'0')}' : '${startDate!.year.toString().padLeft(4,'0')}-${startDate!.month.toString().padLeft(2,'0')}-${startDate!.day.toString().padLeft(2,'0')}',
                'position': posCtrl.text.isNotEmpty? posCtrl.text : null,
                'salary': salaryCtrl.text.isNotEmpty? double.tryParse(salaryCtrl.text) : null,
                'content': contentCtrl.text.isNotEmpty? contentCtrl.text : null,
              };
              await apiPost('/offers', body);
              if (context.mounted) Navigator.pop(context);
            }catch(e){ setState(()=> error='Gửi thư thất bại'); }
          }, child: const Text('Gửi')),
        ],
      );
    }));
  }
  @override Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Sàng lọc & Đánh giá'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _runScreening)],
      ),
      body: Column(children:[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children:[
            Expanded(child: DropdownButtonFormField<int?>(
              initialValue: _selectedJobId,
              items: [const DropdownMenuItem<int>(value: null, child: Text('Chọn công việc')),
                ..._jobs.map((j)=> DropdownMenuItem<int?>(value: j['id'] as int, child: Text(j['title']?.toString()??'')))
              ],
              onChanged: (v){ setState(()=> _selectedJobId=v); },
              decoration: const InputDecoration(labelText: 'Công việc'),
            )),
            const SizedBox(width: 8),
            SizedBox(width: 160, child: DropdownButtonFormField<int>(
              initialValue: _minPercent,
              decoration: const InputDecoration(labelText: 'Tối thiểu %'),
              items: const [0,50,60,70,80,90,100].map((p)=> DropdownMenuItem<int>(value:p, child: Text('≥ $p%'))).toList(),
              onChanged: (v){ if (v!=null) setState(()=> _minPercent=v); },
            )),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _runScreening, child: const Text('Lọc tự động'))
          ]),
        ),
        if (_job!=null) Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Align(alignment: Alignment.centerLeft, child: Text('Yêu cầu: '+_requirementsText(_job!), style: Theme.of(c).textTheme.bodySmall))),
        Expanded(child: ListView.separated(
          key: ValueKey(_tick),
          itemCount: _results.where((r){ return _calcPercent(r) >= _minPercent; }).length,
          separatorBuilder: (_, __)=> const Divider(height:1),
          itemBuilder: (_, i){ final visible = _results.where((r){ return _calcPercent(r) >= _minPercent; }).toList(); final r = visible[i];
            final pc = _calcPercent(r);
            return ListTile(
              leading: CircleAvatar(child: Text('$pc%')), 
              title: Text(r['full_name']?.toString()??''),
              subtitle: Text('${r['email']??''} • ${r['status']??''}'),
              trailing: IconButton(icon: const Icon(Icons.mail_outline), tooltip: 'Gửi thông báo', onPressed: ()=> _sendOfferFromResult(c, r)),
              onTap: (){ final id = r['application_id']; if (id is int) c.push('/applications/$id', extra: {'scores': r['scores'], 'email': r['email'], 'from':'/evaluations'}); },
            );
          },
        ))
      ]),
    );
  }
}
class InterviewsScreen extends StatefulWidget { const InterviewsScreen({super.key}); @override State<InterviewsScreen> createState()=> _InterviewsScreenState(); }
class _InterviewsScreenState extends State<InterviewsScreen>{
  int _tick = 0;
  Future<List<dynamic>> _load(BuildContext c) async {
    final role = c.read<AuthState>().role;
    final me = c.read<AuthState>().user ?? {};
    final meId = me['id'];
    final myEmail = (me['email']?.toString() ?? '').toLowerCase();

    final params = <String,dynamic>{};
    if (role != 'admin') params['mine'] = 'true';
    final raw = await apiGetList('/interviews', params: params);
    final items = raw.cast<Map<String,dynamic>>();

    if (role == 'admin') return items;

    // Additional client-side filtering to enforce visibility even if server ignores params
    final filtered = <Map<String,dynamic>>[];
    for (final itv in items){
      final appId = itv['application_id'];
      if (appId is! int) continue;
      try{
        final app = await apiGet('/applications/$appId');
        // Candidate: only interviews for their own application email
        if (role == 'candidate'){
          final email = (app['email']?.toString() ?? '').toLowerCase();
          if (email.isNotEmpty && email == myEmail) filtered.add(itv);
          continue;
        }
        // Recruiter: only interviews for jobs they own (posted_by == meId)
        if (role == 'recruiter'){
          final jobId = app['job_id'];
          if (jobId is int){
            try{
              final job = await apiGet('/jobs/$jobId');
              if (job['posted_by'] == meId) filtered.add(itv);
            }catch(_){ /* ignore job fetch errors */ }
          }
        }
      }catch(_){ /* ignore app fetch errors */ }
    }
    return filtered;
  }
  @override
  Widget build(BuildContext c){
    final role = c.watch<AuthState>().role;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Lịch phỏng vấn'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> setState(()=> _tick++))],
      ),
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
            initialValue: mode,
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
              // Gửi thông báo mời phỏng vấn đến thí sinh (dùng cơ chế thông báo hiện có)
              final dateOnly = '${when.year.toString().padLeft(4,'0')}-${when.month.toString().padLeft(2,'0')}-${when.day.toString().padLeft(2,'0')}';
              final content = 'Kính gửi ${selectedApp!['full_name']},<br/>Bạn được mời tham gia phỏng vấn vào lúc ${when.toLocal().toIso8601String()} (${mode}).<br/>Địa điểm: ${loc.text.trim().isEmpty? '(sẽ cập nhật)' : loc.text.trim()}.';
              try{
                await apiPost('/offers', {
                  'application_id': selectedApp!['id'],
                  'start_date': dateOnly,
                  'position': 'Phỏng vấn',
                  'salary': null,
                  'content': content,
                });
              }catch(_){ /* ignore notification errors */ }
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
            initialValue: mode,
            decoration: const InputDecoration(labelText:'Hình thức'),
            items: const [
              DropdownMenuItem(value:'online', child: Text('online')),
              DropdownMenuItem(value:'offline', child: Text('offline')),
            ],
            onChanged: (v){ if (v!=null) setState(()=> mode=v); },
          ),
          DropdownButtonFormField<String>(
            initialValue: status,
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
              'scheduled_at': scheduledAt?.toIso8601String(),
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
class CommitteesScreen extends StatelessWidget {
  const CommitteesScreen({super.key});
  @override
  Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Hội đồng tuyển dụng'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> c.go('/committees'))],
      ),
      body: const Center(child: Text('Hội đồng tuyển dụng - TODO xây UI và API')),
    );
  }
}
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
        
  Widget build(BuildContext c){
    final role = c.watch<AuthState>().role;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Kết quả tuyển dụng'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> setState(()=> _tick++))],
      ),
      body: Column(children: [
        if (role=='admin' || role=='recruiter') Padding(
          padding: const EdgeInsets.all(8.0), child: Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              initialValue: _selectedJobId,
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
            initialValue: resultValue,
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
            initialValue: resultValue,
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
  int _tick = 0;
  Future<List<dynamic>> _load(BuildContext c) async {
    final role = c.read<AuthState>().role;
    final items = await apiGetList('/offers', params: _buildParams(role));
    if (role == 'candidate'){
      // Candidate sees: all interview invitations; other notifications only if they passed/got offer/accepted/hired
      try{
        final results = await apiGetList('/results', params: {'mine':'true'});
        final allowed = results.where((r){
          final v = (r['result']?.toString() ?? '').toLowerCase();
          return v=='passed' || v=='offer' || v=='accepted' || v=='hired';
        }).map<int?>((r)=> r['application_id'] as int?).whereType<int>().toSet();
        return items.where((o){
          final pos = (o['position']?.toString() ?? '');
          if (pos.toLowerCase()=='phỏng vấn' || pos.toLowerCase()=='phong van') return true; // interview invites always visible
          final appId = o['application_id'];
          return appId is int && allowed.contains(appId);
        }).toList();
      }catch(_){ return items; }
    }
    return items;
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
        appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Thông báo'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> setState(()=> _tick++))],
      ),
        body: FutureBuilder<List<dynamic>>(
        key: ValueKey(_tick),
        future: _load(c),
        builder: (context, snap){
          if (snap.connectionState!=ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Chưa có thông báo'));
          return Column(children: [
            if (role=='admin' || role=='recruiter') Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(builder: (context, constraints){
                final isNarrow = constraints.maxWidth < 720;
                final cols = (role=='admin') ? 3 : 2;
                final gap = 8.0;
                final fieldWidth = isNarrow ? constraints.maxWidth : (constraints.maxWidth - gap*(cols-1)) / cols;
                return Wrap(spacing: gap, runSpacing: gap, children: [
                  SizedBox(width: fieldWidth, child: DropdownButtonFormField<int>(
                    initialValue: _selectedJobId,
                    items: [
                      const DropdownMenuItem<int>(value: null, child: Text('Tất cả công việc')),
                      ..._jobs.map((j)=> DropdownMenuItem<int>(value: j['id'] as int, child: Text(j['title']?.toString()??'')))
                    ],
                    onChanged: (v){ setState(()=> _selectedJobId = v); },
                    decoration: const InputDecoration(labelText: 'Lọc theo công việc'),
                  )),
                  if (role=='admin') SizedBox(width: fieldWidth, child: DropdownButtonFormField<int>(
                    initialValue: _selectedSenderId,
                    items: [
                      const DropdownMenuItem<int>(value: null, child: Text('Tất cả người gửi')),
                      ..._senders.map((u)=> DropdownMenuItem<int>(value: u['id'] as int, child: Text('${u['full_name']} (${u['email']})')))
                    ],
                    onChanged: (v){ setState(()=> _selectedSenderId = v); },
                    decoration: const InputDecoration(labelText: 'Lọc theo người gửi'),
                  )),
                  SizedBox(width: fieldWidth, child: TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm theo tên hoặc email'), onSubmitted: (_)=> setState((){}))),
                ]);
              })
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
      title: const Text('Chi tiết thông báo'),
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
    if (mounted) setState(()=> _tick++);
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
        title: Text(offer==null? 'Tạo thông báo' : 'Cập nhật thông báo'),
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
          TextField(controller: contentCtrl, maxLines: 6, decoration: const InputDecoration(labelText: 'Nội dung thông báo (HTML)')),
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
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Ứng viên của tôi'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> setState((){}))],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              initialValue: _selectedJobId,
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
                  trailing: IconButton(icon: const Icon(Icons.mail_outline), tooltip: 'Gửi thông báo', onPressed: ()=> _composeOfferFromApp(context, a)),
                );
              },
            );
          },
        ))
      ]),
    );
  }
  Future<void> _composeOfferFromApp(BuildContext c, Map<String,dynamic> app) async {
  final defaultHtml = 'Xin chào ${app['full_name']},<br/>Thông báo từ bộ phận tuyển dụng...';
    DateTime? startDate;
    final posCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    final contentCtrl = TextEditingController(text: defaultHtml);
    String? error;
    await showDialog(context: c, builder: (_) => StatefulBuilder(builder: (context, setState){
      return AlertDialog(
  title: Text('Gửi thông báo cho ${app['full_name']}'),
        content: SingleChildScrollView(child: Column(children: [
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
          TextField(controller: contentCtrl, maxLines: 6, decoration: const InputDecoration(labelText: 'Nội dung thông báo (HTML)')),
          if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
        ])),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () async {
            try{
              final body = {
                'application_id': app['id'],
                'start_date': startDate==null? '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2,'0')}-${DateTime.now().day.toString().padLeft(2,'0')}' : '${startDate!.year.toString().padLeft(4,'0')}-${startDate!.month.toString().padLeft(2,'0')}-${startDate!.day.toString().padLeft(2,'0')}',
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

// Candidate: view application detail, job info and poster, with cancel button
class ApplicationDetailScreen extends StatefulWidget {
  final int appId; final Map<String,dynamic>? initialScores;
  const ApplicationDetailScreen({super.key, required this.appId, this.initialScores});
  @override State<ApplicationDetailScreen> createState()=> _ApplicationDetailScreenState();
}
class _ApplicationDetailScreenState extends State<ApplicationDetailScreen>{
  Map<String,dynamic>? app; Map<String,dynamic>? job; Map<String,dynamic>? poster; Map<String,dynamic>? profile; bool loading=true; String? error; List<CriteriaDef> _criteria = const [];
  Future<void> _load() async {
    try{
      // Load criteria for labeling score keys
      try{ _criteria = await fetchCriteria(); } catch(_){ _criteria = const []; }
      app = await apiGet('/applications/${widget.appId}');
      if (app!=null){
        job = await apiGet('/jobs/${app!['job_id']}');
        final posterId = job?['posted_by'];
        if (posterId!=null){
          try{ poster = await apiGet('/users/$posterId/summary'); } catch(e){ /* May be restricted */ }
        }
        try{
          final email = app!['email']?.toString();
          if (email!=null && email.isNotEmpty){
            final role = context.read<AuthState>().role;
            final meEmail = context.read<AuthState>().user?['email']?.toString();
            if (role == 'candidate' && meEmail!=null && meEmail.toLowerCase() == email.toLowerCase()){
              // Candidate viewing their own application: use /profiles/me to avoid 403
              try{
                profile = await apiGet('/profiles/me');
              }catch(_){
                // Fallback to by-email if server allows; ignore errors otherwise
                try{ profile = await apiGet('/profiles/by-email', params: {'email': email}); }catch(__){}
              }
            } else {
              // Recruiter/Admin or different email: use by-email endpoint
              profile = await apiGet('/profiles/by-email', params: {'email': email});
            }
          }
        }catch(_){ /* ignore */ }
      }
    }catch(e){ error='Không tải được chi tiết ứng tuyển'; }
    if (mounted) setState(()=> loading=false);
  }
  @override void initState(){ super.initState(); _load(); }
  Future<void> _cancel() async {
    final ok = await showDialog<bool>(context: context, builder: (dialogCtx)=> AlertDialog(
      title: const Text('Hủy ứng tuyển'), content: const Text('Bạn có chắc muốn hủy ứng tuyển này?'),
      actions: [TextButton(onPressed: ()=> Navigator.pop(dialogCtx, false), child: const Text('Không')), ElevatedButton(onPressed: ()=> Navigator.pop(dialogCtx, true), child: const Text('Hủy'))],
    ));
    if (ok!=true) return;
    try{
      await apiPut('/applications/${widget.appId}', {'status':'canceled'});
    }catch(_){ try{ await apiDelete('/applications/${widget.appId}'); } catch(__){} }
    if (!mounted) return; context.pop(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy ứng tuyển')));
  }
  @override
  Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: (){
          // Prefer popping back to Evaluations if we navigated from there; otherwise to Applications.
          if (Navigator.of(c).canPop()) { c.pop(); return; }
          final from = (widget.initialScores is Map<String,dynamic>) ? (widget.initialScores as Map<String,dynamic>)['from']?.toString() : null;
          if (from == '/evaluations') { c.go('/evaluations'); } else { c.go('/applications'); }
        }),
        title: const Text('Chi tiết ứng tuyển'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: loading
    ? const Center(child: CircularProgressIndicator())
    : error != null
        ? Center(child: Text(error!))
        : Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView( // 👈 Thêm phần này
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (job != null) ...[
                    Text(job!['title']?.toString() ?? '',
                        style: Theme.of(c).textTheme.titleLarge),
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
                  const SizedBox(height: 8),
                  if (app != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(app!['full_name']?.toString() ?? '',
                                style: Theme.of(c).textTheme.titleMedium),
                            Text(
                                '${app!['email'] ?? ''} • Trạng thái: ${app!['status'] ?? ''}${job != null ? '\nCông việc: ${job!['title'] ?? ''}' : ''}'),
                            if ((app!['phone']?.toString() ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('SĐT: ${app!['phone']}'),
                              ),
                            if ((app!['resume_url']?.toString() ?? '')
                                .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    const Text('CV: '),
                                    Expanded(
                                      child: Text(
                                        app!['resume_url']?.toString() ?? '',
                                        style: const TextStyle(
                                            decoration:
                                                TextDecoration.underline),
                                      ),
                                    ),
                                    IconButton(
                                        icon: const Icon(Icons.copy),
                                        tooltip: 'Sao chép link',
                                        onPressed: () => Clipboard.setData(
                                            ClipboardData(
                                                text: app!['resume_url']
                                                        ?.toString() ??
                                                    '')))
                                  ],
                                ),
                              ),
                            if ((app!['cover_letter']?.toString() ?? '')
                                .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                    'Thư ứng tuyển:\n${app!['cover_letter']}'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Hồ sơ thí sinh',
                          style: Theme.of(c).textTheme.titleMedium)),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (_) {
                      final scoresDyn =
                          profile?['scores'] ?? widget.initialScores?['scores'];
                      final Map<String, dynamic> scores =
                          (scoresDyn is Map)
                              ? Map<String, dynamic>.from(scoresDyn)
                              : {};
                      final extra = (profile?['extra'] is Map)
                          ? Map<String, dynamic>.from(profile!['extra'])
                          : {};
                      if (scores.isEmpty && (extra['notes'] == null)) {
                        return const Text('Chưa có hồ sơ');
                      }

                      String _labelFor(String key) {
                        try {
                          return _criteria
                              .firstWhere((c) => c.key == key)
                              .label;
                        } catch (_) {
                          return key;
                        }
                      }

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (scores.isNotEmpty) ...[
                                Text('Điểm hồ sơ',
                                    style:
                                        Theme.of(c).textTheme.titleSmall),
                                const SizedBox(height: 4),
                                ...scores.entries
                                    .map((e) => Text(
                                        '${_labelFor(e.key)}: ${e.value}'))
                                    .toList(),
                                const SizedBox(height: 8),
                              ],
                              if ((extra['notes']?.toString() ?? '')
                                  .isNotEmpty) ...[
                                Text('Ghi chú',
                                    style:
                                        Theme.of(c).textTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text(extra['notes'].toString()),
                              ],
                              if (extra['certificates'] is List &&
                                  (extra['certificates'] as List)
                                      .isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('Chứng chỉ',
                                    style:
                                        Theme.of(c).textTheme.titleSmall),
                                const SizedBox(height: 4),
                                ...List<Map<String, dynamic>>.from(
                                        extra['certificates'])
                                    .map((cert) {
                                  final type =
                                      (cert['type']?.toString() ?? '')
                                          .trim();
                                  final name =
                                      (cert['name']?.toString() ?? '')
                                          .trim();
                                  final url =
                                      (cert['url']?.toString() ?? '')
                                          .trim();
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            '• ${name.isEmpty ? '(Chưa đặt tên)' : name}${type.isEmpty ? '' : ' ($type)'}'),
                                        if (url.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(
                                                    left: 16, top: 2),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(url,
                                                      style: const TextStyle(
                                                          decoration:
                                                              TextDecoration
                                                                  .underline)),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.copy,
                                                      size: 18),
                                                  tooltip:
                                                      'Sao chép link',
                                                  onPressed: () =>
                                                      Clipboard.setData(
                                                          ClipboardData(
                                                              text: url)),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _cancel,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Hủy ứng tuyển'),
                    ),
                  ),
                ],
              ),
            ),
          ),

    );
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
            initialValue: _selectedJobId,
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
    try{ 
      job = await apiGet('/jobs/${widget.jobId}');
      // Prefill from logged-in user info
      final me = context.read<AuthState>().user;
      if (me!=null){
        _name.text = me['full_name']?.toString() ?? _name.text;
        _email.text = me['email']?.toString() ?? _email.text;
      }
      // Prefill from prior application for this job if exists
      try{
        final apps = await apiGetList('/applications', params: {'mine':'true', 'job_id': widget.jobId});
        if (apps.isNotEmpty){
          final a = (apps.first as Map<String,dynamic>);
          _name.text = a['full_name']?.toString() ?? _name.text;
          _email.text = a['email']?.toString() ?? _email.text;
          _phone.text = a['phone']?.toString() ?? _phone.text;
          _resume.text = a['resume_url']?.toString() ?? _resume.text;
          _cover.text = a['cover_letter']?.toString() ?? _cover.text;
        }
      }catch(_){ /* ignore prefill errors */ }
    }
    catch(e){ error='Không tải được công việc'; }
    setState(()=> loading=false);
  }
  @override void dispose(){ _name.dispose(); _email.dispose(); _phone.dispose(); _resume.dispose(); _cover.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: Text(job!=null? job!['title']?.toString()??'Chi tiết công việc' : 'Chi tiết công việc'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: loading? const Center(child: CircularProgressIndicator()) : error!=null? Center(child: Text(error!)) : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(job!['title']?.toString()??'', style: Theme.of(c).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(job!['description']?.toString()??''),
          if (job!['requirements']!=null) ...[
            const SizedBox(height: 12),
            Text('Yêu cầu', style: Theme.of(c).textTheme.titleMedium),
            Text(_requirementsText(job!), style: Theme.of(c).textTheme.bodyMedium),
          ],
          const Divider(height: 32),
          if ((job!['status']?.toString() ?? 'open') == 'closed') ...[
            Text('Công việc đã kết thúc, không thể nộp hồ sơ', style: TextStyle(color: Colors.red.shade700)),
          ] else ...[
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
          ]
        ]),
      ),
    );
  }
}
String _requirementsText(Map<String,dynamic> job){
  final scores = (job['requirements']?['scores']??{}) as Map<String,dynamic>;
  if (scores.isEmpty) return 'Không có yêu cầu cụ thể';
  // We don't have criteria labels here; fall back to showing keys as-is.
  final parts = <String>[];
  scores.forEach((k, v){ final min=v['min']; final imp=v['important']==true; final label=k; if (min!=null) parts.add('${imp?'* ':''}$label ≥ $min'); });
  return parts.join(' • ');
}

// Admin screen to manage criteria list
class CriteriaAdminScreen extends StatefulWidget { const CriteriaAdminScreen({super.key}); @override State<CriteriaAdminScreen> createState()=> _CriteriaAdminScreenState(); }
class _CriteriaAdminScreenState extends State<CriteriaAdminScreen>{
  int _tick=0; final _search=TextEditingController();
  Future<List<dynamic>> _load() async { final list = await apiGetList('/criteria'); final q=_search.text.trim().toLowerCase(); if (q.isEmpty) return list; return list.where((e){ final m=(e as Map).map((k,v)=> MapEntry('$k','${v??''}'.toLowerCase())); return (m['key']??'').contains(q) || (m['label']??'').contains(q); }).toList(); }
  @override void dispose(){ _search.dispose(); super.dispose(); }
  @override Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Tiêu chí đánh giá'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> setState(()=> _tick++))],
      ),
      body: Column(children:[
        Padding(padding: const EdgeInsets.all(8), child: TextField(controller: _search, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText:'Tìm theo key/label'), onSubmitted: (_)=> setState(()=> _tick++))),
        Expanded(child: FutureBuilder<List<dynamic>>(
          key: ValueKey(_tick), future: _load(), builder:(context,snap){
            if (snap.connectionState!=ConnectionState.done) return const Center(child:CircularProgressIndicator());
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
            final items = (snap.data??[]).cast<Map<String,dynamic>>();
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __)=> const Divider(height:1),
              itemBuilder: (_, i){ final it=items[i]; return ListTile(
                title: Text('${it['label']} • ${it['key']}'),
                subtitle: Text('min:${it['min']} max:${it['max']} step:${it['step']} • active:${it['active']}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children:[
                  IconButton(icon: const Icon(Icons.edit), onPressed: () async { final changed = await _editDialog(context, it); if (changed==true && mounted) setState(()=> _tick++); }),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { try{ await apiDelete('/criteria/${it['id']}'); setState(()=> _tick++);} catch(_){}}),
                ]),
              ); },
            );
          })
        )
      ]),
      floatingActionButton: FloatingActionButton(onPressed: () async { final changed = await _createDialog(context); if (changed==true && mounted) setState(()=> _tick++); }, child: const Icon(Icons.add)),
    );
  }
  Future<bool?> _createDialog(BuildContext c) async {
    final keyC=TextEditingController(); final labelC=TextEditingController(); final minC=TextEditingController(text:'0'); final maxC=TextEditingController(text:'100'); final stepC=TextEditingController(text:'1'); bool active=true; String? error;
    bool changed=false;
    await showDialog(context:c, builder:(_)=> StatefulBuilder(builder:(context,setState){ return AlertDialog(
      title: const Text('Thêm tiêu chí'), content: SingleChildScrollView(child: Column(children:[
        TextField(controller:keyC, decoration: const InputDecoration(labelText:'Key (ví dụ: ielts)')),
        TextField(controller:labelC, decoration: const InputDecoration(labelText:'Nhãn hiển thị')),
        Row(children:[ Expanded(child: TextField(controller:minC, decoration: const InputDecoration(labelText:'Min'), keyboardType: TextInputType.number)), const SizedBox(width:8), Expanded(child: TextField(controller:maxC, decoration: const InputDecoration(labelText:'Max'), keyboardType: TextInputType.number)) ]),
        TextField(controller:stepC, decoration: const InputDecoration(labelText:'Bước'), keyboardType: TextInputType.number),
        CheckboxListTile(value: active, onChanged: (v)=> setState(()=> active=v==true), title: const Text('Kích hoạt')),
        if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
      ])),
      actions: [ TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async { try{
          await apiPost('/criteria', { 'key': keyC.text.trim(), 'label': labelC.text.trim(), 'min': double.tryParse(minC.text), 'max': double.tryParse(maxC.text), 'step': double.tryParse(stepC.text), 'active': active });
          changed=true; if (context.mounted) Navigator.pop(context);
        }catch(e){ setState(()=> error='Lưu thất bại'); } }, child: const Text('Lưu')) ],
    ); }));
    return changed;
  }
  Future<bool?> _editDialog(BuildContext c, Map<String,dynamic> it) async {
    final keyC=TextEditingController(text: '${it['key']??''}'); final labelC=TextEditingController(text: '${it['label']??''}'); final minC=TextEditingController(text:'${it['min']??0}'); final maxC=TextEditingController(text:'${it['max']??100}'); final stepC=TextEditingController(text:'${it['step']??1}'); bool active=(it['active']==true); String? error;
    bool changed=false;
    await showDialog(context:c, builder:(_)=> StatefulBuilder(builder:(context,setState){ return AlertDialog(
      title: const Text('Sửa tiêu chí'), content: SingleChildScrollView(child: Column(children:[
        TextField(controller:keyC, decoration: const InputDecoration(labelText:'Key')),
        TextField(controller:labelC, decoration: const InputDecoration(labelText:'Nhãn')),
        Row(children:[ Expanded(child: TextField(controller:minC, decoration: const InputDecoration(labelText:'Min'), keyboardType: TextInputType.number)), const SizedBox(width:8), Expanded(child: TextField(controller:maxC, decoration: const InputDecoration(labelText:'Max'), keyboardType: TextInputType.number)) ]),
        TextField(controller:stepC, decoration: const InputDecoration(labelText:'Bước'), keyboardType: TextInputType.number),
        CheckboxListTile(value: active, onChanged: (v)=> setState(()=> active=v==true), title: const Text('Kích hoạt')),
        if (error!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(error!, style: const TextStyle(color: Colors.red)))
      ])),
      actions: [ TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async { try{
          await apiPut('/criteria/${it['id']}', { 'key': keyC.text.trim(), 'label': labelC.text.trim(), 'min': double.tryParse(minC.text), 'max': double.tryParse(maxC.text), 'step': double.tryParse(stepC.text), 'active': active });
          changed=true; if (context.mounted) Navigator.pop(context);
        }catch(e){ setState(()=> error='Lưu thất bại'); } }, child: const Text('Lưu')) ],
    ); }));
    return changed;
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

// removed unused _Scaffold helper after replacing with concrete screens

// Admin: User management
class UsersScreen extends StatefulWidget { const UsersScreen({super.key}); @override State<UsersScreen> createState()=> _UsersScreenState(); }
class _UsersScreenState extends State<UsersScreen>{
  int _tick=0; final _search = TextEditingController();
  Future<List<dynamic>> _load() => apiGetList('/users', params: _search.text.isEmpty? {} : {'q': _search.text});
  @override void dispose(){ _search.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> c.go('/')),
        title: const Text('Quản lý người dùng'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: ()=> setState(()=> _tick++))],
      ),
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
            initialValue: role,
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
            initialValue: role,
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
