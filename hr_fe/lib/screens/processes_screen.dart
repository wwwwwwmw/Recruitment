import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
