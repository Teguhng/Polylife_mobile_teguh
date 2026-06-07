import 'package:flutter/material.dart';

class AllErrorBanner extends StatelessWidget {
  final String message;

  const AllErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        border: Border.all(color: const Color(0xFFFDA4AF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFBE123C),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
