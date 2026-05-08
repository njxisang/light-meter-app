import 'package:flutter/material.dart';

/// 使用帮助对话框
class HelpDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(
          children: [
            const Text(
              '使用帮助',
              style: TextStyle(color: Colors.white),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 100), () {
                  OpticalKnowledgeDialog.show(context);
                });
              },
              child: const Text(
                '光学知识 >',
                style: TextStyle(color: Color(0xFFE94560)),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                '什么是Lux?',
                'Lux是照度单位，表示单位面积上的光通量。',
              ),
              _buildHelpItem(
                '场景说明',
                '应用会根据当前Lux值自动识别场景类型。',
              ),
              _buildHelpItem(
                '推荐参数',
                '基于摄影曝光公式计算，仅供参考。',
              ),
              _buildHelpItem(
                '拍摄模式',
                '不同模式会对曝光进行微调，以适应不同拍摄需求。',
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              const SizedBox(height: 8),
              _buildOpticalKnowledgeCard(context),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  static Widget _buildHelpItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE94560),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  static Widget _buildOpticalKnowledgeCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 100), () {
          OpticalKnowledgeDialog.show(context);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE94560).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.school, color: Color(0xFFE94560), size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '光学知识栏目',
                style: TextStyle(
                  color: Color(0xFFE94560),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: Color(0xFFE94560), size: 14),
          ],
        ),
      ),
    );
  }
}

/// 光学知识对话框
class OpticalKnowledgeDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Row(
          children: [
            Icon(Icons.school, color: Color(0xFFE94560)),
            SizedBox(width: 8),
            Text(
              '光学知识',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _KnowledgeSection(
                title: '光圈 (Aperture)',
                icon: Icons.camera,
                content:
                    '• f值越小，光圈越大（如f/1.8），进光量越多，背景虚化效果强\n'
                    '• f值越大，光圈越小（如f/16），进光量越少，场景整体清晰\n\n'
                    '手机镜头光圈固定为f/1.8，但可通过模拟方式调节虚化程度。',
              ),
              _KnowledgeSection(
                title: 'ISO（感光度）',
                icon: Icons.iso,
                content:
                    '• 低ISO（如50-100）：画面纯净，细节丰富，适合光线充足的场景\n'
                    '• 中ISO（如200-800）：噪点开始增加，但仍可接受\n'
                    '• 高ISO（如1600+）：噪点明显，画质下降，适合暗光环境\n\n'
                    '建议尽量使用低ISO以获得最佳画质。',
              ),
              _KnowledgeSection(
                title: '快门速度 (Shutter Speed)',
                icon: Icons.shutter_speed,
                content:
                    '• 高速快门（如1/1000s）：定格瞬间运动，适合拍摄运动物体\n'
                    '• 低速快门（如1/30s）：记录运动轨迹，可能产生模糊\n\n'
                    '手持拍摄时，快门速度建议不低于1/60s，避免手抖造成模糊。',
              ),
              _KnowledgeSection(
                title: '曝光三角',
                icon: Icons.exposure,
                content:
                    '光圈、ISO、快门速度三者相互制约，共同决定曝光量(EV)。\n\n'
                    '• 光圈固定时：ISO↑ + 快门↓ 或 ISO↓ + 快门↑\n'
                    '• 保持相同曝光：增大一档光圈，必须提高ISO或加快快门',
              ),
              _KnowledgeSection(
                title: '参数选择建议',
                icon: Icons.lightbulb_outline,
                content:
                    '【人像摄影】优先大光圈(f/1.8-2.8)获得背景虚化\n'
                    '【风景摄影】使用中等光圈(f/5.6-8)获得整体清晰\n'
                    '【运动摄影】优先保证高速快门(1/500s以上)\n'
                    '【暗光摄影】接受高ISO以获得可用的快门速度',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('我学会了'),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final String content;

  const _KnowledgeSection({
    required this.title,
    required this.icon,
    required this.content,
  });

  @override
  State<_KnowledgeSection> createState() => _KnowledgeSectionState();
}

class _KnowledgeSectionState extends State<_KnowledgeSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(widget.icon, color: const Color(0xFFE94560), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                widget.content,
                style: TextStyle(color: Colors.grey[300], fontSize: 12, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}
