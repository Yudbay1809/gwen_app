import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          readOnly: true,
          onTap: () => context.go('/search'),
          decoration: InputDecoration(
            hintText: 'Search skincare, makeup, fragrance...',
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
