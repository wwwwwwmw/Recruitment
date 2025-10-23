import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_state.dart';

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
