import 'package:flutter/material.dart';

class FilledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscure;
  final Widget? trailing;
  final void Function(String)? onSubmit;
  final Color? bg;

  const FilledField({
    required super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscure = false,
    this.trailing,
    this.onSubmit,
    this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: trailing,
        filled: true,
        fillColor: (bg ?? cs.surface).withValues(alpha: 0.92),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      obscureText: obscure,
      onSubmitted: onSubmit,
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined, size: 56, color: cs.outline),
          const SizedBox(height: 8),
          Text('Henüz cihaz yok', style: TextStyle(color: cs.outline)),
          const SizedBox(height: 4),
          const Text('“Taramayı Başlat”a basmayı dene.'),
        ],
      ),
    );
  }
}

class MockDevice {
  final String name;
  final String id;
  const MockDevice({required this.name, required this.id});
}
