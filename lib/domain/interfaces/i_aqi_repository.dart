import 'package:vayu/domain/models/aqi_reading.dart';
import 'package:vayu/domain/models/forecast_point.dart';

abstract class IAqiRepository {
  /// Stream of real-time AQI readings for the given location.
  Stream<AqiReading> watchCurrentAqi(double lat, double lng);

  /// Fetch a single current AQI reading for the given location.
  Future<AqiReading?> getAqi(double lat, double lng);

  /// Fetch historical AQI data for the given location over a date range.
  Future<List<AqiReading>> getHistory(double lat, double lng, DateTime start, DateTime end);

  /// Fetch forecast AQI data.
  Future<List<ForecastPoint>> getForecast(double lat, double lng);
}
