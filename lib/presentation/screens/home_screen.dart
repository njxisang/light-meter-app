import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../providers/light_sensor_provider.dart';
import '../widgets/lux_display.dart';
import '../widgets/exposure_card.dart';
import '../widgets/scene_selector.dart';
import '../widgets/history_chart.dart';
import '../widgets/help_dialog.dart';

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
            onPressed: () => HelpDialog.show(context),
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
              onPressed: () => HelpDialog.show(context),
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
      builder: (context) => _SettingsDialog(),
    );
  }
}

/// 设置对话框
class _SettingsDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<_SettingsDialog> {
  late int _selectedInterval;
  late int _selectedSmoothSize;

  static const List<int> _intervalOptions = [20, 50, 100, 200, 500];
  static const List<int> _smoothOptions = [3, 5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    _selectedInterval = ref.read(sensorIntervalMsProvider);
    _selectedSmoothSize = ref.read(smoothSizeProvider);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text(
        '设置',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 采样间隔
          _buildSettingTile(
            icon: Icons.timer,
            title: '采样间隔',
            subtitle: '光线传感器采样频率',
            value: '${_selectedInterval}ms',
            onTap: () => _showIntervalPicker(context),
          ),
          const SizedBox(height: 8),
          // 数据平滑
          _buildSettingTile(
            icon: Icons.blur_on,
            title: '数据平滑',
            subtitle: '滑动平均采样次数',
            value: '$_selectedSmoothSize次',
            onTap: () => _showSmoothPicker(context),
          ),
        ],
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
            // 保存设置
            ref.read(sensorIntervalMsProvider.notifier).state = _selectedInterval;
            ref.read(smoothSizeProvider.notifier).state = _selectedSmoothSize;
            ref.read(sharedPreferencesProvider).setInt('settings_sensor_interval_ms', _selectedInterval);
            ref.read(sharedPreferencesProvider).setInt('settings_smooth_size', _selectedSmoothSize);
            // 更新传感器参数
            ref.read(lightSensorProvider.notifier).updateSmoothParams(
              intervalMs: _selectedInterval,
              smoothSize: _selectedSmoothSize,
            );
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[400], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE94560).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: const TextStyle(color: Color(0xFFE94560), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _showIntervalPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('采样间隔', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _intervalOptions.map((interval) {
            return RadioListTile<int>(
              title: Text('${interval}ms', style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                interval <= 50 ? '灵敏' : interval <= 100 ? '平衡' : '省电',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              value: interval,
              groupValue: _selectedInterval,
              activeColor: const Color(0xFFE94560),
              onChanged: (v) {
                setState(() => _selectedInterval = v!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSmoothPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('数据平滑', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _smoothOptions.map((smooth) {
            return RadioListTile<int>(
              title: Text('$smooth次平均', style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                smooth <= 3 ? '灵敏' : smooth <= 10 ? '平衡' : '稳定',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              value: smooth,
              groupValue: _selectedSmoothSize,
              activeColor: const Color(0xFFE94560),
              onChanged: (v) {
                setState(() => _selectedSmoothSize = v!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
