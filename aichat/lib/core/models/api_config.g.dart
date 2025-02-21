// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ApiConfigAdapter extends TypeAdapter<ApiConfig> {
  @override
  final int typeId = 2;

  @override
  ApiConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApiConfig(
      id: fields[0] as String?,
      name: fields[1] as String,
      baseUrl: fields[2] as String,
      apiKey: fields[3] as String,
      defaultModel: fields[4] as String,
      isEnabled: fields[5] as bool,
      additionalHeaders: (fields[6] as Map?)?.cast<String, dynamic>(),
      availableModels: (fields[7] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ApiConfig obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.baseUrl)
      ..writeByte(3)
      ..write(obj.apiKey)
      ..writeByte(4)
      ..write(obj.defaultModel)
      ..writeByte(5)
      ..write(obj.isEnabled)
      ..writeByte(6)
      ..write(obj.additionalHeaders)
      ..writeByte(7)
      ..write(obj.availableModels);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
