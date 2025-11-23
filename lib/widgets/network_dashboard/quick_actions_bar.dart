import 'package:flutter/material.dart';
import '../../screens/resource_sharing_page.dart';

class QuickActionsBar extends StatelessWidget {
  final VoidCallback onQuickMessage;

  const QuickActionsBar({
    super.key,
    required this.onQuickMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onQuickMessage,
              icon: const Icon(Icons.message),
              label: const Text('Quick Message'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResourceSharingPage(),
                ),
              ),
              icon: const Icon(Icons.inventory),
              label: const Text('Resources'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

