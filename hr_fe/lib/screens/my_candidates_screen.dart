import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api.dart';

class MyCandidatesScreen extends StatefulWidget { const MyCandidatesScreen({super.key}); @override State<MyCandidatesScreen> createState()=> _MyCandidatesScreenState(); }
class _MyCandidatesScreenState extends State<MyCandidatesScreen>{
  final _search = TextEditingController();
  int? _selectedJobId; List<Map<String,dynamic>> _jobs = [];
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
  @override void initState(){ super.initState(); _loadJobs(); }
  Future<void> _loadJobs() async {
    final list = await apiGetList('/jobs', params: {'mine':'true'});
    setState(()=> _jobs = list.map((e)=> e is Map ? Map<String,dynamic>.from(e) : <String,dynamic>{}).toList());
  }
  Future<List<dynamic>> _load() async {
    final p = <String,dynamic>{'mine':'true'};
    if (_selectedJobId != null) p['job_id'] = _selectedJobId;
    if (_search.text.isNotEmpty) p['q'] = _search.text;
    final list = await apiGetList('/applications', params: p);
    // Hide applications that have already been rejected for recruiter view
    return list.where((e){
      try{
        final status = (e as Map<String,dynamic>)['status']?.toString().toLowerCase();
        return status != 'rejected';
      } catch(_){
        return true;
      }
    }).toList();
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
            if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
            final items = snap.data ?? [];
            if (items.isEmpty) return const Center(child: Text('Chưa có ứng viên'));
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __)=> const Divider(height: 1),
              itemBuilder: (_, i){
                final raw = items[i];
                final a = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
                return ListTile(
                  title: Text(a['full_name']?.toString()??''),
                  subtitle: Text('${a['email']??''} • Trạng thái: ${_viStatus(a['status']?.toString())}'),
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
