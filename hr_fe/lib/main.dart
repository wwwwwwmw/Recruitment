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
            GoRoute(path: '/jobs', builder: (_, __) => const JobsScreen()),
            GoRoute(path: '/processes', builder: (_, __) => const ProcessesScreen()),
            GoRoute(path: '/applications', builder: (_, __) => const ApplicationsScreen()),
            GoRoute(path: '/evaluations', builder: (_, __) => const EvaluationsScreen()),
            GoRoute(path: '/interviews', builder: (_, __) => const InterviewsScreen()),
            GoRoute(path: '/committees', builder: (_, __) => const CommitteesScreen()),
            GoRoute(path: '/results', builder: (_, __) => const ResultsScreen()),
            GoRoute(path: '/offers', builder: (_, __) => const OffersScreen()),
            GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
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
    final List<_NavTile> tiles = [];
    if (role == 'admin' || role == 'recruiter') {
      tiles.addAll([
        _NavTile('Thiết lập quy trình', '/processes', Icons.account_tree),
        _NavTile('Đăng tin tuyển dụng', '/jobs', Icons.work_outline),
        _NavTile('Sàng lọc/Đánh giá', '/evaluations', Icons.rate_review_outlined),
        _NavTile('Lịch phỏng vấn', '/interviews', Icons.event_outlined),
      ]);
    }
    if (role == 'admin') {
      tiles.addAll([
        _NavTile('Hội đồng tuyển dụng', '/committees', Icons.group_work_outlined),
        _NavTile('Báo cáo', '/reports', Icons.pie_chart_outline),
      ]);
    }
    tiles.addAll([
      _NavTile('Việc làm', '/jobs', Icons.work_history_outlined),
      _NavTile('Ứng tuyển của tôi', '/applications', Icons.people_alt_outlined),
      _NavTile('Thư mời nhận việc', '/offers', Icons.mail_outline),
      _NavTile('Kết quả', '/results', Icons.verified_outlined),
    ]);
    return Scaffold(
      appBar: AppBar(title: const Text('HR Recruitment Dashboard'), actions: [
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
class JobsScreen extends StatelessWidget { 
  const JobsScreen({super.key}); 
  @override 
  Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng tin tuyển dụng')),
      body: FutureBuilder<List<dynamic>>(
        future: apiGetList('/jobs'),
        builder: (context, snap){
          if (snap.connectionState!=ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final items = snap.data ?? [];
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __)=> const Divider(height: 1),
            itemBuilder: (_, i){
              final j = items[i] as Map<String, dynamic>;
              return ListTile(title: Text(j['title']?.toString()??'Untitled'), subtitle: Text(j['department']?.toString()??''));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){},
        child: const Icon(Icons.add),
      ),
    );
  }
}
class ProcessesScreen extends StatelessWidget { const ProcessesScreen({super.key}); @override Widget build(BuildContext c)=> _Scaffold(title:'Thiết lập quy trình'); }
class ApplicationsScreen extends StatelessWidget { 
  const ApplicationsScreen({super.key}); 
  @override 
  Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ ứng viên')),
      body: FutureBuilder<List<dynamic>>(
        future: apiGetList('/applications'),
        builder: (context, snap){
          if (snap.connectionState!=ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final items = snap.data ?? [];
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __)=> const Divider(height: 1),
            itemBuilder: (_, i){
              final a = items[i] as Map<String, dynamic>;
              return ListTile(title: Text(a['full_name']?.toString()??'No name'), subtitle: Text(a['email']?.toString()??''));
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
class InterviewsScreen extends StatelessWidget { const InterviewsScreen({super.key}); @override Widget build(BuildContext c)=> _Scaffold(title:'Lịch phỏng vấn'); }
class CommitteesScreen extends StatelessWidget { const CommitteesScreen({super.key}); @override Widget build(BuildContext c)=> _Scaffold(title:'Hội đồng tuyển dụng'); }
class ResultsScreen extends StatelessWidget { const ResultsScreen({super.key}); @override Widget build(BuildContext c)=> _Scaffold(title:'Kết quả tuyển dụng'); }
class OffersScreen extends StatelessWidget { const OffersScreen({super.key}); @override Widget build(BuildContext c)=> _Scaffold(title:'Thư mời nhận việc'); }
class ReportsScreen extends StatelessWidget { const ReportsScreen({super.key}); @override Widget build(BuildContext c)=> _Scaffold(title:'Báo cáo thống kê'); }

class _Scaffold extends StatelessWidget {
  final String title;
  const _Scaffold({required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [
        IconButton(icon: const Icon(Icons.home), onPressed: ()=> context.go('/')),
        IconButton(icon: const Icon(Icons.logout), onPressed: ()=> context.read<AuthState>().logout())
      ]),
      body: Center(
        child: Text('$title - TODO: build UI and call backend APIs'),
      ),
    );
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
