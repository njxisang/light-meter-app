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
                '100ms',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
            ListTile(
              title: const Text(
                '数据平滑',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Text(
                '10次平均',
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
        title: const Text(
          '使用帮助',
          style: TextStyle(color: Colors.white),
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
