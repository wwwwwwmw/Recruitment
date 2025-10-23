import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api.dart';

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
          const _SectionTitle('Tổng quan'),
          FutureBuilder<Map<String,dynamic>>(
            future: apiGet('/reports/summary', params: _params()),
            builder:(context,snap){
              if (snap.connectionState!=ConnectionState.done) return const _Loading();
              if (snap.hasError) return _Error(snap.error.toString());
              final s = snap.data ?? {};
              return Card(child: ListTile(
                title: Text('Hồ sơ ứng tuyển: ${s['totalApps']??0} • Thông báo (đã gửi): ${s['totalOffers']??0}'),
                subtitle: Text('Kết quả: Đạt ${s['passed']??0} • Không đạt ${s['failed']??0} • Công việc: ${s['totalJobs']??0}'),
              ));
            },
          ),
          const SizedBox(height: 12),
          const _SectionTitle('Trạng thái hồ sơ (pipeline)'),
          FutureBuilder<List<dynamic>>(
            future: apiGetList('/reports/pipeline', params: _params()),
            builder:(context,snap){
              if (snap.connectionState!=ConnectionState.done) return const _Loading();
              if (snap.hasError) return _Error(snap.error.toString());
              final items = (snap.data ?? []).cast<Map<String,dynamic>>();
              if (items.isEmpty) return const _Empty('Không có dữ liệu pipeline');
              return Column(children: items.map((it)=> ListTile(
                title: Text(_viStatus('${it['status']??''}')),
                trailing: Text('${it['count']??0}'),
              )).toList());
            },
          ),
          const SizedBox(height: 12),
          const _SectionTitle('Kết quả tổng hợp (theo loại)'),
          FutureBuilder<List<dynamic>>(
            future: apiGetList('/reports/outcomes', params: _params()),
            builder:(context,snap){
              if (snap.connectionState!=ConnectionState.done) return const _Loading();
              if (snap.hasError) return _Error(snap.error.toString());
              final items = (snap.data ?? []).cast<Map<String,dynamic>>();
              if (items.isEmpty) return const _Empty('Không có dữ liệu kết quả');
              return Column(children: items.map((it)=> ListTile(
                title: Text(_viResult('${it['result']??''}')),
                trailing: Text('${it['count']??0}'),
              )).toList());
            },
          ),
          const SizedBox(height: 12),
          const _SectionTitle('Chi tiết kết quả'),
          FutureBuilder<List<dynamic>>(
            future: apiGetList('/reports/outcome-detail', params: _params()),
            builder:(context,snap){
              if (snap.connectionState!=ConnectionState.done) return const _Loading();
              if (snap.hasError) return _Error(snap.error.toString());
              final items = (snap.data ?? []).cast<Map<String,dynamic>>();
              if (items.isEmpty) return const _Empty('Không có kết quả');
              return Column(children: items.map((it)=> ListTile(
                title: Text('${_viResult('${it['result']??''}')} • ${it['job_title']??''}'),
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

// Vietnamese label helpers
String _viStatus(String s){
  switch(s.toLowerCase()){
    case 'submitted': return 'Đã nộp';
    case 'screening': return 'Sàng lọc';
    case 'interviewing': return 'Phỏng vấn';
    case 'offered': return 'Đã gửi thông báo';
    case 'hired': return 'Nhận việc';
    case 'rejected': return 'Từ chối/Không đạt';
    case 'failed': return 'Không đạt';
    case 'accepted': return 'Đã chấp nhận';
  }
  return s; // fallback
}

String _viResult(String r){
  switch(r.toLowerCase()){
    case 'passed': return 'Đạt';
    case 'failed': return 'Không đạt';
    case 'rejected': return 'Từ chối';
    case 'hired': return 'Nhận việc';
    case 'offer': return 'Đã gửi thông báo';
    case 'accepted': return 'Chấp nhận';
  }
  return r; // fallback
}
