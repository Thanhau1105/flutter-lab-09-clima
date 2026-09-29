import 'package:flutter/material.dart';

import '../services/location.dart';
import '../services/networking.dart';
import '../weather_model.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key, required this.weather, required this.location});

  final WeatherRepository weather;
  final LocationRepository location;

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _cityController = TextEditingController();
  WeatherData? _weather;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _request(Future<WeatherData> Function() load) async {
    if (_loading) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await load();
      if (!mounted) {
        return;
      }
      setState(() => _weather = result);
    } on WeatherFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on LocationFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Đã có lỗi xảy ra. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _searchCity() =>
      _request(() => widget.weather.byCity(_cityController.text));

  void _useLocation() => _request(() async {
    if (!widget.weather.isConfigured) {
      throw const WeatherFailure(
        'Chưa có OpenWeatherMap API key. Dán key vào config/api_key.txt rồi chạy lại.',
      );
    }
    final coordinates = await widget.location.current();
    return widget.weather.byCoordinates(
      coordinates.latitude,
      coordinates.longitude,
    );
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0B1731),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0B1731),
      title: const Text(
        'CLIMA',
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3),
      ),
      actions: [
        IconButton(
          key: const Key('location-button'),
          tooltip: 'Thời tiết vị trí hiện tại',
          onPressed: _loading ? null : _useLocation,
          icon: const Icon(Icons.my_location_rounded),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1731), Color(0xFF193A61), Color(0xFF315E86)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 44,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Thời tiết hôm nay',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tìm thành phố hoặc dùng vị trí của bạn',
                    style: TextStyle(color: Color(0xFFB7CCE0), fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  _searchField(),
                  const SizedBox(height: 18),
                  if (!widget.weather.isConfigured) ...[
                    _notice(
                      Icons.key_rounded,
                      'Cần OpenWeatherMap API key để xem dữ liệu thật. Dán key vào config/api_key.txt rồi chạy lại.',
                      const Color(0xFFFFD48A),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (_error != null) ...[
                    _notice(
                      Icons.error_outline_rounded,
                      _error!,
                      const Color(0xFFFFB8B8),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (_loading) ...[
                    const SizedBox(height: 80),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 16),
                    const Center(child: Text('Đang cập nhật thời tiết...')),
                  ] else if (_weather != null)
                    _weatherContent(_weather!)
                  else
                    _emptyState(),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Dữ liệu thời tiết từ OpenWeatherMap',
                      style: TextStyle(color: Color(0xFFB7CCE0), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _searchField() => TextField(
    key: const Key('city-field'),
    controller: _cityController,
    textInputAction: TextInputAction.search,
    onSubmitted: (_) => _searchCity(),
    decoration: InputDecoration(
      hintText: 'Ví dụ: Hà Nội, Đà Nẵng...',
      hintStyle: const TextStyle(color: Color(0xFFB7CCE0)),
      prefixIcon: const Icon(Icons.location_city_rounded),
      suffixIcon: IconButton(
        key: const Key('search-button'),
        tooltip: 'Tìm thành phố',
        onPressed: _loading ? null : _searchCity,
        icon: const Icon(Icons.search_rounded),
      ),
      filled: true,
      fillColor: const Color(0xFF253C5E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    ),
  );

  Widget _notice(IconData icon, String message, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.55)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message, style: TextStyle(color: color)),
        ),
      ],
    ),
  );

  Widget _emptyState() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 74),
    child: Column(
      children: [
        Icon(Icons.cloud_outlined, size: 112, color: Color(0xFFB7DFFF)),
        SizedBox(height: 22),
        Text(
          'Bầu trời của bạn đang chờ',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        Text(
          'Nhập tên thành phố hoặc chạm biểu tượng vị trí ở góc trên.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFB7CCE0), height: 1.5),
        ),
      ],
    ),
  );

  Widget _weatherContent(WeatherData data) => Column(
    children: [
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.place_rounded,
                  size: 20,
                  color: Color(0xFFB7DFFF),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    data.city,
                    key: const Key('weather-city'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 34),
            Icon(data.icon, size: 112, color: const Color(0xFFFFDC89)),
            const SizedBox(height: 12),
            Text(
              '${data.temperature.round()}°',
              key: const Key('weather-temperature'),
              style: const TextStyle(fontSize: 92, fontWeight: FontWeight.w300),
            ),
            Text(
              data.description,
              key: const Key('weather-description'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: _detail(
              Icons.thermostat_rounded,
              'Cảm giác',
              '${data.feelsLike.round()}°C',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _detail(
              Icons.water_drop_rounded,
              'Độ ẩm',
              '${data.humidity}%',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _detail(
              Icons.air_rounded,
              'Gió',
              '${data.windSpeed.toStringAsFixed(1)} m/s',
            ),
          ),
        ],
      ),
    ],
  );

  Widget _detail(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFFB7DFFF)),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFFB7CCE0)),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
