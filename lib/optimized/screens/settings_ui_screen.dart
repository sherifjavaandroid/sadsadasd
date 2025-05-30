import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import '../code/performance_monitor.dart';
import '../managers/advanced_settings_manager.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  @override
  _AdvancedSettingsScreenState createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AdvancedSettingsManager _settingsManager = AdvancedSettingsManager();

  // متغيرات الإعدادات المحلية
  late PerformanceSettings _performanceSettings;
  late NetworkSettings _networkSettings;
  late DeveloperSettings _developerSettings;

  bool _isLoading = true;
  String _selectedPreset = 'balanced';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settingsManager.loadSettings();
    setState(() {
      _performanceSettings = _settingsManager.performanceSettings;
      _networkSettings = _settingsManager.networkSettings;
      _developerSettings = _settingsManager.developerSettings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('الإعدادات المتقدمة')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('الإعدادات المتقدمة'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.speed), text: 'الأداء'),
            Tab(icon: Icon(Icons.network_check), text: 'الشبكة'),
            Tab(icon: Icon(Icons.developer_mode), text: 'المطور'),
            Tab(icon: Icon(Icons.analytics), text: 'التحليلات'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _autoOptimize,
            tooltip: 'تحسين تلقائي',
          ),
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'export', child: Text('تصدير الإعدادات')),
              PopupMenuItem(value: 'import', child: Text('استيراد الإعدادات')),
              PopupMenuItem(value: 'reset', child: Text('إعادة تعيين')),
              PopupMenuItem(value: 'test', child: Text('اختبار الأداء')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPerformanceTab(),
          _buildNetworkTab(),
          _buildDeveloperTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اختيار الإعداد المُحدد مسبقاً
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الإعدادات المُحددة مسبقاً',
                      style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildPresetChip('power_saver', '🔋 توفير الطاقة'),
                      _buildPresetChip('balanced', '⚖️ متوازن'),
                      _buildPresetChip('performance', '⚡ أداء عالي'),
                      _buildPresetChip('ultra', '🚀 فائق'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // الإعدادات المفصلة
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إعدادات مفصلة',
                      style: Theme.of(context).textTheme.titleLarge),

                  SizedBox(height: 16),

                  // التحميل المتزامن
                  _buildSliderSetting(
                    title: 'التحميل المتزامن',
                    subtitle: 'عدد الفيديوهات المحملة في نفس الوقت',
                    value: _performanceSettings.maxConcurrentLoads.toDouble(),
                    min: 1,
                    max: 6,
                    divisions: 5,
                    onChanged: (value) {
                      setState(() {
                        _performanceSettings = _performanceSettings.copyWith(
                          maxConcurrentLoads: value.round(),
                        );
                      });
                    },
                  ),

                  // مسافة التحميل المسبق
                  _buildSliderSetting(
                    title: 'مسافة التحميل المسبق',
                    subtitle: 'عدد الفيديوهات المحملة مسبقاً',
                    value: _performanceSettings.preloadDistance.toDouble(),
                    min: 0,
                    max: 5,
                    divisions: 5,
                    onChanged: (value) {
                      setState(() {
                        _performanceSettings = _performanceSettings.copyWith(
                          preloadDistance: value.round(),
                        );
                      });
                    },
                  ),

                  // حجم الكاش
                  _buildSliderSetting(
                    title: 'حجم الكاش',
                    subtitle: 'عدد الفيديوهات المحفوظة في الذاكرة',
                    value: _performanceSettings.cacheSize.toDouble(),
                    min: 4,
                    max: 20,
                    divisions: 16,
                    onChanged: (value) {
                      setState(() {
                        _performanceSettings = _performanceSettings.copyWith(
                          cacheSize: value.round(),
                        );
                      });
                    },
                  ),

                  // جودة الفيديو
                  _buildSliderSetting(
                    title: 'جودة الفيديو',
                    subtitle: 'جودة الفيديوهات المحملة',
                    value: _performanceSettings.videoQuality,
                    min: 0.5,
                    max: 1.0,
                    divisions: 5,
                    onChanged: (value) {
                      setState(() {
                        _performanceSettings = _performanceSettings.copyWith(
                          videoQuality: value,
                        );
                      });
                    },
                  ),

                  // الخيارات المنطقية
                  SwitchListTile(
                    title: Text('التحميل الخلفي'),
                    subtitle: Text('تحميل الفيديوهات في الخلفية'),
                    value: _performanceSettings.enableBackgroundLoading,
                    onChanged: (value) {
                      setState(() {
                        _performanceSettings = _performanceSettings.copyWith(
                          enableBackgroundLoading: value,
                        );
                      });
                    },
                  ),

                  SwitchListTile(
                    title: Text('التحميل المسبق'),
                    subtitle: Text('تحميل الفيديوهات القادمة مسبقاً'),
                    value: _performanceSettings.enablePreloading,
                    onChanged: (value) {
                      setState(() {
                        _performanceSettings = _performanceSettings.copyWith(
                          enablePreloading: value,
                        );
                      });
                    },
                  ),

                  SwitchListTile(
                    title: Text('تحسين الذاكرة'),
                    subtitle: Text('تنظيف الذاكرة تلقائياً'),
                    value: _performanceSettings.enableMemoryOptimization,
                    onChanged: (value) {
                      setState(() {
                        _performanceSettings = _performanceSettings.copyWith(
                          enableMemoryOptimization: value,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // أزرار الحفظ والإلغاء
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _savePerformanceSettings,
                  child: Text('حفظ الإعدادات'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetPerformanceSettings,
                  child: Text('إعادة تعيين'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('وضع توفير البيانات'),
                  subtitle: Text('تقليل جودة الفيديو لتوفير البيانات'),
                  value: _networkSettings.enableDataSaver,
                  onChanged: (value) {
                    setState(() {
                      _networkSettings = NetworkSettings(
                        enableDataSaver: value,
                        enableWifiOnlyHQ: _networkSettings.enableWifiOnlyHQ,
                        connectionTimeout: _networkSettings.connectionTimeout,
                        requestTimeout: _networkSettings.requestTimeout,
                        enableRetry: _networkSettings.enableRetry,
                        enableCompression: _networkSettings.enableCompression,
                      );
                    });
                  },
                ),
                SwitchListTile(
                  title: Text('جودة عالية على الـ WiFi فقط'),
                  subtitle: Text('تشغيل جودة عالية على شبكة WiFi فقط'),
                  value: _networkSettings.enableWifiOnlyHQ,
                  onChanged: (value) {
                    setState(() {
                      _networkSettings = NetworkSettings(
                        enableDataSaver: _networkSettings.enableDataSaver,
                        enableWifiOnlyHQ: value,
                        connectionTimeout: _networkSettings.connectionTimeout,
                        requestTimeout: _networkSettings.requestTimeout,
                        enableRetry: _networkSettings.enableRetry,
                        enableCompression: _networkSettings.enableCompression,
                      );
                    });
                  },
                ),
                SwitchListTile(
                  title: Text('إعادة المحاولة التلقائية'),
                  subtitle: Text('إعادة المحاولة عند فشل التحميل'),
                  value: _networkSettings.enableRetry,
                  onChanged: (value) {
                    setState(() {
                      _networkSettings = NetworkSettings(
                        enableDataSaver: _networkSettings.enableDataSaver,
                        enableWifiOnlyHQ: _networkSettings.enableWifiOnlyHQ,
                        connectionTimeout: _networkSettings.connectionTimeout,
                        requestTimeout: _networkSettings.requestTimeout,
                        enableRetry: value,
                        enableCompression: _networkSettings.enableCompression,
                      );
                    });
                  },
                ),
                SwitchListTile(
                  title: Text('ضغط البيانات'),
                  subtitle: Text('ضغط البيانات المرسلة والمستقبلة'),
                  value: _networkSettings.enableCompression,
                  onChanged: (value) {
                    setState(() {
                      _networkSettings = NetworkSettings(
                        enableDataSaver: _networkSettings.enableDataSaver,
                        enableWifiOnlyHQ: _networkSettings.enableWifiOnlyHQ,
                        connectionTimeout: _networkSettings.connectionTimeout,
                        requestTimeout: _networkSettings.requestTimeout,
                        enableRetry: _networkSettings.enableRetry,
                        enableCompression: value,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveNetworkSettings,
            child: Text('حفظ إعدادات الشبكة'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('وضع المطور'),
                  subtitle: Text('تفعيل ميزات المطور المتقدمة'),
                  value: _developerSettings.enableDebugMode,
                  onChanged: (value) {
                    setState(() {
                      _developerSettings = DeveloperSettings(
                        enableDebugMode: value,
                        enablePerformanceLogging:
                            _developerSettings.enablePerformanceLogging,
                        enableNetworkLogging:
                            _developerSettings.enableNetworkLogging,
                        enableMemoryMonitoring:
                            _developerSettings.enableMemoryMonitoring,
                        showPerformanceOverlay:
                            _developerSettings.showPerformanceOverlay,
                        logLevel: _developerSettings.logLevel,
                      );
                    });
                  },
                ),
                if (_developerSettings.enableDebugMode) ...[
                  SwitchListTile(
                    title: Text('تسجيل الأداء'),
                    subtitle: Text('تسجيل مفصل لأداء التطبيق'),
                    value: _developerSettings.enablePerformanceLogging,
                    onChanged: (value) {
                      setState(() {
                        _developerSettings = DeveloperSettings(
                          enableDebugMode: _developerSettings.enableDebugMode,
                          enablePerformanceLogging: value,
                          enableNetworkLogging:
                              _developerSettings.enableNetworkLogging,
                          enableMemoryMonitoring:
                              _developerSettings.enableMemoryMonitoring,
                          showPerformanceOverlay:
                              _developerSettings.showPerformanceOverlay,
                          logLevel: _developerSettings.logLevel,
                        );
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text('تسجيل الشبكة'),
                    subtitle: Text('تسجيل جميع طلبات الشبكة'),
                    value: _developerSettings.enableNetworkLogging,
                    onChanged: (value) {
                      setState(() {
                        _developerSettings = DeveloperSettings(
                          enableDebugMode: _developerSettings.enableDebugMode,
                          enablePerformanceLogging:
                              _developerSettings.enablePerformanceLogging,
                          enableNetworkLogging: value,
                          enableMemoryMonitoring:
                              _developerSettings.enableMemoryMonitoring,
                          showPerformanceOverlay:
                              _developerSettings.showPerformanceOverlay,
                          logLevel: _developerSettings.logLevel,
                        );
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text('مراقبة الذاكرة'),
                    subtitle: Text('مراقبة استهلاك الذاكرة'),
                    value: _developerSettings.enableMemoryMonitoring,
                    onChanged: (value) {
                      setState(() {
                        _developerSettings = DeveloperSettings(
                          enableDebugMode: _developerSettings.enableDebugMode,
                          enablePerformanceLogging:
                              _developerSettings.enablePerformanceLogging,
                          enableMemoryMonitoring: value,
                          showPerformanceOverlay:
                              _developerSettings.showPerformanceOverlay,
                          logLevel: _developerSettings.logLevel,
                          enableNetworkLogging:
                              _developerSettings.enableNetworkLogging,
                        );
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text('عرض معلومات الأداء'),
                    subtitle: Text('عرض معلومات الأداء على الشاشة'),
                    value: _developerSettings.showPerformanceOverlay,
                    onChanged: (value) {
                      setState(() {
                        _developerSettings = DeveloperSettings(
                          enableDebugMode: _developerSettings.enableDebugMode,
                          enablePerformanceLogging:
                              _developerSettings.enablePerformanceLogging,
                          enableNetworkLogging:
                              _developerSettings.enableNetworkLogging,
                          enableMemoryMonitoring:
                              _developerSettings.enableMemoryMonitoring,
                          showPerformanceOverlay: value,
                          logLevel: _developerSettings.logLevel,
                        );
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveDeveloperSettings,
                  child: Text('حفظ الإعدادات'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _runDiagnostics,
                  child: Text('تشغيل التشخيص'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAnalyticsCard('إحصائيات الأداء', _buildPerformanceStats()),
          SizedBox(height: 16),
          _buildAnalyticsCard('إحصائيات التحميل', _buildLoadingStats()),
          SizedBox(height: 16),
          _buildAnalyticsCard('إحصائيات الذاكرة', _buildMemoryStats()),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _generateReport,
                  child: Text('إنشاء تقرير مفصل'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _clearStats,
                  child: Text('مسح الإحصائيات'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String preset, String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedPreset == preset,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPreset = preset;
          });
          _applyPreset(preset);
        }
      },
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: Text(value.toStringAsFixed(value % 1 == 0 ? 0 : 1)),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, Widget content) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceStats() {
    return Column(
      children: [
        _buildStatRow('متوسط FPS', '60.0'),
        _buildStatRow('متوسط وقت التحميل', '1.5s'),
        _buildStatRow('استهلاك الذاكرة', '85 MB'),
        _buildStatRow('معدل نجاح التحميل', '95%'),
      ],
    );
  }

  Widget _buildLoadingStats() {
    return Column(
      children: [
        _buildStatRow('إجمالي التحميلات', '245'),
        _buildStatRow('التحميلات الناجحة', '232'),
        _buildStatRow('التحميلات الفاشلة', '13'),
        _buildStatRow('معدل استخدام الكاش', '78%'),
      ],
    );
  }

  Widget _buildMemoryStats() {
    return Column(
      children: [
        _buildStatRow('كونترولرز نشطة', '8'),
        _buildStatRow('حجم الكاش الحالي', '12 فيديو'),
        _buildStatRow('ذروة الاستهلاك', '120 MB'),
        _buildStatRow('عمليات التنظيف', '15'),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // معالجات الأحداث
  void _applyPreset(String preset) async {
    await _settingsManager.applyPreset(preset);
    await _loadSettings();
    _showSnackBar('تم تطبيق الإعداد: $preset');
  }

  void _savePerformanceSettings() async {
    await _settingsManager.updatePerformanceSettings(_performanceSettings);
    _showSnackBar('تم حفظ إعدادات الأداء');
  }

  void _saveNetworkSettings() async {
    await _settingsManager.updateNetworkSettings(_networkSettings);
    _showSnackBar('تم حفظ إعدادات الشبكة');
  }

  void _saveDeveloperSettings() async {
    await _settingsManager.updateDeveloperSettings(_developerSettings);
    _showSnackBar('تم حفظ إعدادات المطور');
  }

  void _resetPerformanceSettings() async {
    await _settingsManager.applyPreset('balanced');
    await _loadSettings();
    _showSnackBar('تم إعادة تعيين إعدادات الأداء');
  }

  void _autoOptimize() async {
    _showLoadingDialog('جاري التحسين التلقائي...');
    await _settingsManager.autoOptimize();
    await _loadSettings();
    Navigator.of(context).pop();
    _showSnackBar('تم التحسين التلقائي بنجاح');
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'export':
        _exportSettings();
        break;
      case 'import':
        _importSettings();
        break;
      case 'reset':
        _resetAllSettings();
        break;
      case 'test':
        _runPerformanceTest();
        break;
    }
  }

  void _exportSettings() {
    final settings = _settingsManager.exportSettings();
    final jsonString = JsonEncoder.withIndent('  ').convert(settings);

    Clipboard.setData(ClipboardData(text: jsonString));
    _showSnackBar('تم نسخ الإعدادات إلى الحافظة');
  }

  void _importSettings() {
    // هنا يمكن إضافة واجهة لاستيراد الإعدادات
    _showSnackBar('ميزة الاستيراد قيد التطوير');
  }

  void _resetAllSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إعادة تعيين جميع الإعدادات'),
        content: Text(
            'هل أنت متأكد من إعادة تعيين جميع الإعدادات للقيم الافتراضية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _settingsManager.resetToDefaults();
              await _loadSettings();
              _showSnackBar('تم إعادة تعيين جميع الإعدادات');
            },
            child: Text('إعادة تعيين'),
          ),
        ],
      ),
    );
  }

  void _runPerformanceTest() {
    _showSnackBar('جاري تشغيل اختبار الأداء...');
    // هنا يمكن إضافة كود اختبار الأداء
  }

  void _runDiagnostics() {
    _showSnackBar('جاري تشغيل التشخيص...');
    // هنا يمكن إضافة كود التشخيص
  }

  void _generateReport() {
    _showSnackBar('جاري إنشاء التقرير...');
    // هنا يمكن إضافة كود إنشاء التقرير
  }

  void _clearStats() {
    PerformanceMonitor().resetStats();
    _showSnackBar('تم مسح الإحصائيات');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
