import '../device.dart';
import '../component.dart';
import 'components.g.dart';

// builders
Thermometer _buildThermometer(Device device, String mqttId) =>
    Thermometer(device: device, mqttId: mqttId);
Hygrometer _buildHygrometer(Device device, String mqttId) =>
    Hygrometer(device: device, mqttId: mqttId);
VpdMeter _buildVpdMeter(Device device, String mqttId) =>
    VpdMeter(device: device, mqttId: mqttId);
Co2Meter _buildCo2Meter(Device device, String mqttId) =>
    Co2Meter(device: device, mqttId: mqttId);
Phmeter _buildPhmeter(Device device, String mqttId) =>
    Phmeter(device: device, mqttId: mqttId);
ReservoirMeter _buildReservoirMeter(Device device, String mqttId) =>
    ReservoirMeter(device: device, mqttId: mqttId);
LightSensor _buildLightSensor(Device device, String mqttId) =>
    LightSensor(device: device, mqttId: mqttId);
Daytime _buildDaytime(Device device, String mqttId) =>
    Daytime(device: device, mqttId: mqttId);
Ebbflow _buildEbbflow(Device device, String mqttId) =>
    Ebbflow(device: device, mqttId: mqttId);
IntervalIrrigation _buildIntervalIrrigation(Device device, String mqttId) =>
    IntervalIrrigation(device: device, mqttId: mqttId);
EbbflowFlood _buildEbbflowFlood(Device device, String mqttId) =>
    EbbflowFlood(device: device, mqttId: mqttId);
EbbflowDrain _buildEbbflowDrain(Device device, String mqttId) =>
    EbbflowDrain(device: device, mqttId: mqttId);
ReservoirFill _buildReservoirFill(Device device, String mqttId) =>
    ReservoirFill(device: device, mqttId: mqttId);
ReservoirDrain _buildReservoirDrain(Device device, String mqttId) =>
    ReservoirDrain(device: device, mqttId: mqttId);
Lighting _buildLighting(Device device, String mqttId) =>
    Lighting(device: device, mqttId: mqttId);
Exaust _buildExaust(Device device, String mqttId) =>
    Exaust(device: device, mqttId: mqttId);
Humidifier _buildHumidifier(Device device, String mqttId) =>
    Humidifier(device: device, mqttId: mqttId);
Dehumidifier _buildDehumidifier(Device device, String mqttId) =>
    Dehumidifier(device: device, mqttId: mqttId);
HumidifierVpd _buildHumidifierVpd(Device device, String mqttId) =>
    HumidifierVpd(device: device, mqttId: mqttId);
DehumidifierVpd _buildDehumidifierVpd(Device device, String mqttId) =>
    DehumidifierVpd(device: device, mqttId: mqttId);
AirConditioner _buildAirConditioner(Device device, String mqttId) =>
    AirConditioner(device: device, mqttId: mqttId);
Co2Emitter _buildCo2Emitter(Device device, String mqttId) =>
    Co2Emitter(device: device, mqttId: mqttId);

// builder map
const Map<String, Component Function(Device device, String mqttId)> _builders =
    {
  "thermometer": _buildThermometer,
  "temperature": _buildThermometer,
  "hygrometer": _buildHygrometer,
  "humidity": _buildHygrometer,
  "vpd_meter": _buildVpdMeter,
  "vpd-meter": _buildVpdMeter,
  "co2_meter": _buildCo2Meter,
  "co2-meter": _buildCo2Meter,
  "phmeter": _buildPhmeter,
  "reservoir_meter": _buildReservoirMeter,
  "netuno": _buildReservoirMeter,
  "reservoir": _buildReservoirMeter,
  "reservoir-meter": _buildReservoirMeter,
  "light_sensor": _buildLightSensor,
  "light": _buildLightSensor,
  "light-sensor": _buildLightSensor,
  "daytime": _buildDaytime,
  "ebbflow": _buildEbbflow,
  "interval_irrigation": _buildIntervalIrrigation,
  "interval-irrigation": _buildIntervalIrrigation,
  "ebbflow_flood": _buildEbbflowFlood,
  "ebbflow-flood-relay": _buildEbbflowFlood,
  "ebbflow-flood": _buildEbbflowFlood,
  "ebbflow_drain": _buildEbbflowDrain,
  "ebbflow-drain-relay": _buildEbbflowDrain,
  "ebbflow-drain": _buildEbbflowDrain,
  "reservoir_fill": _buildReservoirFill,
  "reservoir-fill-relay": _buildReservoirFill,
  "reservoir-fill": _buildReservoirFill,
  "reservoir_drain": _buildReservoirDrain,
  "reservoir-drain-relay": _buildReservoirDrain,
  "reservoir-drain": _buildReservoirDrain,
  "lighting": _buildLighting,
  "light-relay": _buildLighting,
  "exaust": _buildExaust,
  "exaust-relay": _buildExaust,
  "humidifier": _buildHumidifier,
  "humidifier-relay": _buildHumidifier,
  "dehumidifier": _buildDehumidifier,
  "dehumidifier-relay": _buildDehumidifier,
  "humidifier_vpd": _buildHumidifierVpd,
  "humidifier-vpd": _buildHumidifierVpd,
  "dehumidifier_vpd": _buildDehumidifierVpd,
  "dehumidifier-vpd": _buildDehumidifierVpd,
  "air_conditioner": _buildAirConditioner,
  "air-conditioner-relay": _buildAirConditioner,
  "air-conditioner": _buildAirConditioner,
  "co2_emitter": _buildCo2Emitter,
  "co2-emitter": _buildCo2Emitter
};

class ComponentBuilder {
  static bool isValidId(String id) => _builders.containsKey(id);

  static Component fromId(String id, Device device) {
    final builder = _builders[id];
    if (builder == null) {
      throw Exception("Unknown component '$id'");
    }

    return builder(device, id);
  }
}
