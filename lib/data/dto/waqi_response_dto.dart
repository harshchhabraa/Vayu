class WaqiResponseDto {
  final String status;
  final WaqiDataDto? data;

  WaqiResponseDto({required this.status, this.data});

  factory WaqiResponseDto.fromJson(Map<String, dynamic> json) {
    return WaqiResponseDto(
      status: json['status'] as String,
      data: json['data'] != null ? WaqiDataDto.fromJson(json['data'] as Map<String, dynamic>) : null,
    );
  }
}

class WaqiDataDto {
  final int aqi;
  final int idx;
  final WaqiCityDto city;
  final String dominentpol;
  final WaqiIaqiDto iaqi;
  final WaqiTimeDto time;
  
  WaqiDataDto({
    required this.aqi,
    required this.idx,
    required this.city,
    required this.dominentpol,
    required this.iaqi,
    required this.time,
  });

  factory WaqiDataDto.fromJson(Map<String, dynamic> json) {
    // Sometimes the API returns a string "-" for AQI if the station is down.
    int parsedAqi = 0;
    if (json['aqi'] is int) {
      parsedAqi = json['aqi'] as int;
    } else if (json['aqi'] is String) {
      parsedAqi = int.tryParse(json['aqi'] as String) ?? 0;
    }

    return WaqiDataDto(
      aqi: parsedAqi,
      idx: json['idx'] as int? ?? 0,
      city: WaqiCityDto.fromJson(json['city'] as Map<String, dynamic>),
      dominentpol: json['dominentpol'] as String? ?? 'unknown',
      iaqi: WaqiIaqiDto.fromJson(json['iaqi'] as Map<String, dynamic>? ?? {}),
      time: WaqiTimeDto.fromJson(json['time'] as Map<String, dynamic>),
    );
  }
}

class WaqiCityDto {
  final List<double> geo;
  final String name;

  WaqiCityDto({required this.geo, required this.name});

  factory WaqiCityDto.fromJson(Map<String, dynamic> json) {
    final rawGeo = json['geo'] as List<dynamic>? ?? [0.0, 0.0];
    return WaqiCityDto(
      geo: rawGeo.map((e) => (e as num).toDouble()).toList(),
      name: json['name'] as String? ?? 'Unknown Station',
    );
  }
}

class WaqiIaqiDto {
  final double? pm25;
  final double? pm10;
  final double? o3;
  final double? no2;
  final double? so2;
  final double? co;

  WaqiIaqiDto({this.pm25, this.pm10, this.o3, this.no2, this.so2, this.co});

  factory WaqiIaqiDto.fromJson(Map<String, dynamic> json) {
    double? extractVal(String key) {
      if (json[key] != null && json[key]['v'] != null) {
        return (json[key]['v'] as num).toDouble();
      }
      return null;
    }

    return WaqiIaqiDto(
      pm25: extractVal('pm25'),
      pm10: extractVal('pm10'),
      o3: extractVal('o3'),
      no2: extractVal('no2'),
      so2: extractVal('so2'),
      co: extractVal('co'),
    );
  }
}

class WaqiTimeDto {
  final DateTime iso;

  WaqiTimeDto({required this.iso});

  factory WaqiTimeDto.fromJson(Map<String, dynamic> json) {
    final isoStr = json['iso'] as String?;
    return WaqiTimeDto(
      iso: isoStr != null ? DateTime.tryParse(isoStr) ?? DateTime.now() : DateTime.now(),
    );
  }
}
