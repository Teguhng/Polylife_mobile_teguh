import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AiAppBarAction extends StatelessWidget {
  const AiAppBarAction({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Buka PolyBot AI',
        onPressed: () => context.push('/ai'),
        icon: const Icon(Icons.auto_awesome_rounded),
      );
}
