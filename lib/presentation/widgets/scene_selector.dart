import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/light_sensor_provider.dart';

/// 拍摄模式选择器组件
class SceneSelector extends ConsumerWidget {
  const SceneSelector({super.key});

  static const List<Map<String, dynamic>> _modes = [
    {'id': 'auto', 'label': '自动', 'icon': Icons.auto_awesome},
    {'id': 'portrait', 'label': '人像', 'icon': Icons.person},
    {'id': 'landscape', 'label': '风景', 'icon': Icons.landscape},
    {'id': 'sports', 'label': '运动', 'icon': Icons.sports},
    {'id': 'lowlight', 'label': '暗光', 'icon': Icons.nightlight},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(shootingModeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Text(
              '拍摄模式',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _modes.map((mode) {
                final isSelected = mode['id'] == currentMode;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ModeButton(
                    label: mode['label'],
                    icon: mode['icon'],
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(shootingModeProvider.notifier).state = mode['id'];
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFE94560) : const Color(0xFF16213E),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFE94560)
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey[400],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
