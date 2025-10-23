import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api.dart';

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
            if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
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
              DropdownMenuItem(value:'admin', child: Text('Quản trị')),
              DropdownMenuItem(value:'recruiter', child: Text('Nhà tuyển dụng')),
              DropdownMenuItem(value:'candidate', child: Text('Thí sinh')),
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
              DropdownMenuItem(value:'admin', child: Text('Quản trị')),
              DropdownMenuItem(value:'recruiter', child: Text('Nhà tuyển dụng')),
              DropdownMenuItem(value:'candidate', child: Text('Thí sinh')),
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
