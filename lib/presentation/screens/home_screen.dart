import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/light_sensor_provider.dart';
import '../widgets/lux_display.dart';
import '../widgets/exposure_card.dart';
import '../widgets/scene_selector.dart';
import '../widgets/history_chart.dart';

/// 主屏幕
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final sensorAvailable = ref.watch(sensorAvailableProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '光照计',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.grey),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: sensorAvailable.when(
        data: (isAvailable) => _buildContent(context, isAvailable),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFE94560)),
        ),
        error: (error, stack) => _buildErrorContent(context, error),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isAvailable) {
    if (!isAvailable) {
      return _buildNoSensorContent(context);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 模式选择器
          const SceneSelector(),
          const SizedBox(height: 8),
          // Lux 显示
          const LuxDisplay(),
          const SizedBox(height: 16),
          // 推荐参数卡片
          const ExposureCard(),
          const SizedBox(height: 16),
          // 历史曲线
          const HistoryChart(),
          const SizedBox(height: 24),
          // 底部按钮
          _buildBottomButtons(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNoSensorContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sensors_off,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 24),
            const Text(
              '光线传感器不可用',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '您的设备不支持光线传感器，\n无法自动获取环境照度。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () => _showManualInputDialog(context),
              child: const Text('手动输入Lux值'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            const Text(
              '传感器错误',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showSettingsDialog(context),
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('设置'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: BorderSide(color: Colors.grey[700]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showHelpDialog(context),
              icon: const Icon(Icons.help_outline, size: 18),
              label: const Text('帮助'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: BorderSide(color: Colors.grey[700]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '手动输入Lux',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '例如: 500',
            hintStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE94560)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
            ),
            onPressed: () {
              final lux = double.tryParse(controller.text);
              if (lux != null && lux > 0) {
                ref.read(lightSensorProvider.notifier).startManualMode(lux);
                Navigator.pop(context);
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '设置',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                '采样间隔',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Text(
                '50ms',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
            ListTile(
              title: const Text(
                '数据平滑',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Text(
                '5次平均',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94560),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
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
                final navigator = Navigator.of(context);
                navigator.pop();
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    _showOpticalKnowledgeDialog(navigator.context);
                  }
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
              InkWell(
                onTap: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      _showOpticalKnowledgeDialog(navigator.context);
                    }
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
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _showOpticalKnowledgeDialog(BuildContext context) {
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
              _buildKnowledgeSection(
                '光圈 (Aperture)',
                '光圈是镜头中控制进光量的孔径大小，用f值表示。\n\n'
                    '• f值越小，光圈越大（如f/1.8），进光量越多，背景虚化效果强\n'
                    '• f值越大，光圈越小（如f/16），进光量越少，场景整体清晰\n\n'
                    '手机镜头光圈固定为f/1.8，但可通过模拟方式调节虚化程度。',
              ),
              _buildKnowledgeSection(
                'ISO（感光度）',
                'ISO表示传感器对光线的敏感程度。\n\n'
                    '• 低ISO（如50-100）：画面纯净，细节丰富，适合光线充足的场景\n'
                    '• 中ISO（如200-800）：噪点开始增加，但仍可接受\n'
                    '• 高ISO（如1600+）：噪点明显，画质下降，适合暗光环境\n\n'
                    '建议尽量使用低ISO以获得最佳画质。',
              ),
              _buildKnowledgeSection(
                '快门速度 (Shutter Speed)',
                '快门速度决定曝光时长。\n\n'
                    '• 高速快门（如1/1000s）：定格瞬间运动，适合拍摄运动物体\n'
                    '• 低速快门（如1/30s）：记录运动轨迹，可能产生模糊\n\n'
                    '手持拍摄时，快门速度建议不低于1/60s，避免手抖造成模糊。',
              ),
              _buildKnowledgeSection(
                '曝光三角',
                '光圈、ISO、快门速度三者相互制约，共同决定曝光量(EV)。\n\n'
                    '• 光圈固定时：ISO↑ + 快门↓ 或 ISO↓ + 快门↑\n'
                    '• 保持相同曝光：增大一档光圈，必须提高ISO或加快快门\n\n'
                    '理解三者关系，才能根据拍摄需求灵活调节参数。',
              ),
              _buildKnowledgeSection(
                '如何选择参数组合',
                '根据拍摄场景选择合适的参数：\n\n'
                    '【人像摄影】\n'
                    '• 优先大光圈(f/1.8-2.8)获得背景虚化\n'
                    '• ISO尽量低，快门保持在安全范围\n'
                    '• 必要时接受稍长的快门速度\n\n'
                    '【风景摄影】\n'
                    '• 使用中等光圈(f/5.6-8)获得整体清晰\n'
                    '• 允许较低的ISO保证画质\n'
                    '• 可接受较慢的快门（建议使用三脚架）\n\n'
                    '【运动摄影】\n'
                    '• 优先保证高速快门(1/500s以上)\n'
                    '• 适当提高ISO以确保快门速度\n'
                    '• 画质略降但能定格瞬间\n\n'
                    '【暗光摄影】\n'
                    '• 接受高ISO以获得可用的快门速度\n'
                    '• 噪点总比模糊好\n'
                    '• 可考虑增加人工光源',
              ),
              _buildKnowledgeSection(
                '本应用参数说明',
                '• 光圈选择：可模拟不同光圈值，观察对其他参数的影响\n'
                    '• 推荐组合：显示同一EV下不同光圈对应的ISO和快门组合\n'
                    '• 质量评级：基于ISO值评估画质等级\n\n'
                    '提示：手机摄影以便捷为主，本应用参数仅供参考，实际效果请以实际拍摄为准。',
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

  Widget _buildKnowledgeSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE94560),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(color: Colors.grey[300], fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String content) {
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
}
