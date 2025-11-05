// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'energy_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EnergyDataImpl _$$EnergyDataImplFromJson(Map<String, dynamic> json) =>
    _$EnergyDataImpl(
      timestamp: json['timestamp'] as String,
      watts: (json['watts'] as num).toDouble(),
      applianceId: (json['applianceId'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$EnergyDataImplToJson(_$EnergyDataImpl instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'watts': instance.watts,
      'applianceId': instance.applianceId,
    };
