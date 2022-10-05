import 'components.g.dart';
import '../component.dart';
import '../room.dart';

mixin RoomComponents {
  Thermometer? thermometer;
  Hygrometer? hygrometer;
  VpdMeter? vpdMeter;
  Co2Meter? co2Meter;
  Phmeter? phmeter;
  ReservoirMeter? reservoirMeter;
  LightSensor? lightSensor;
  Daytime? daytime;
  Ebbflow? ebbflow;
  IntervalIrrigation? intervalIrrigation;
  EbbflowFlood? ebbflowFlood;
  EbbflowDrain? ebbflowDrain;
  ReservoirFill? reservoirFill;
  ReservoirDrain? reservoirDrain;
  Lighting? lighting;
  Exaust? exaust;
  Humidifier? humidifier;
  Dehumidifier? dehumidifier;
  HumidifierVpd? humidifierVpd;
  DehumidifierVpd? dehumidifierVpd;
  AirConditioner? airConditioner;
  Co2Emitter? co2Emitter;

  // available components
  List<Component> get components => [
        if (thermometer != null) thermometer!,
        if (hygrometer != null) hygrometer!,
        if (vpdMeter != null) vpdMeter!,
        if (co2Meter != null) co2Meter!,
        if (phmeter != null) phmeter!,
        if (reservoirMeter != null) reservoirMeter!,
        if (lightSensor != null) lightSensor!,
        if (daytime != null) daytime!,
        if (ebbflow != null) ebbflow!,
        if (intervalIrrigation != null) intervalIrrigation!,
        if (ebbflowFlood != null) ebbflowFlood!,
        if (ebbflowDrain != null) ebbflowDrain!,
        if (reservoirFill != null) reservoirFill!,
        if (reservoirDrain != null) reservoirDrain!,
        if (lighting != null) lighting!,
        if (exaust != null) exaust!,
        if (humidifier != null) humidifier!,
        if (dehumidifier != null) dehumidifier!,
        if (humidifierVpd != null) humidifierVpd!,
        if (dehumidifierVpd != null) dehumidifierVpd!,
        if (airConditioner != null) airConditioner!,
        if (co2Emitter != null) co2Emitter!
      ];

  // hasComponent
  bool? hasComponent(String componentId) {
    switch (componentId) {
      case 'thermometer':
      case 'temperature':
        return thermometer != null;

      case 'hygrometer':
      case 'humidity':
        return hygrometer != null;

      case 'vpd_meter':
      case 'vpd-meter':
        return vpdMeter != null;

      case 'co2_meter':
      case 'co2-meter':
        return co2Meter != null;

      case 'phmeter':
        return phmeter != null;

      case 'reservoir_meter':
      case 'netuno':
      case 'reservoir':
      case 'reservoir-meter':
        return reservoirMeter != null;

      case 'light_sensor':
      case 'light':
      case 'light-sensor':
        return lightSensor != null;

      case 'daytime':
        return daytime != null;

      case 'ebbflow':
        return ebbflow != null;

      case 'interval_irrigation':
      case 'interval-irrigation':
        return intervalIrrigation != null;

      case 'ebbflow_flood':
      case 'ebbflow-flood-relay':
      case 'ebbflow-flood':
        return ebbflowFlood != null;

      case 'ebbflow_drain':
      case 'ebbflow-drain-relay':
      case 'ebbflow-drain':
        return ebbflowDrain != null;

      case 'reservoir_fill':
      case 'reservoir-fill-relay':
      case 'reservoir-fill':
        return reservoirFill != null;

      case 'reservoir_drain':
      case 'reservoir-drain-relay':
      case 'reservoir-drain':
        return reservoirDrain != null;

      case 'lighting':
      case 'light-relay':
        return lighting != null;

      case 'exaust':
      case 'exaust-relay':
        return exaust != null;

      case 'humidifier':
      case 'humidifier-relay':
        return humidifier != null;

      case 'dehumidifier':
      case 'dehumidifier-relay':
        return dehumidifier != null;

      case 'humidifier_vpd':
      case 'humidifier-vpd':
        return humidifierVpd != null;

      case 'dehumidifier_vpd':
      case 'dehumidifier-vpd':
        return dehumidifierVpd != null;

      case 'air_conditioner':
      case 'air-conditioner-relay':
      case 'air-conditioner':
        return airConditioner != null;

      case 'co2_emitter':
      case 'co2-emitter':
        return co2Emitter != null;

      default:
        return null;
    }
  }

  // getComponent
  Component getComponent(String componentId) {
    switch (componentId) {
      case 'thermometer':
      case 'temperature':
        return thermometer ??=
            Thermometer(room: this as Room, mqttId: componentId);

      case 'hygrometer':
      case 'humidity':
        return hygrometer ??=
            Hygrometer(room: this as Room, mqttId: componentId);

      case 'vpd_meter':
      case 'vpd-meter':
        return vpdMeter ??= VpdMeter(room: this as Room, mqttId: componentId);

      case 'co2_meter':
      case 'co2-meter':
        return co2Meter ??= Co2Meter(room: this as Room, mqttId: componentId);

      case 'phmeter':
        return phmeter ??= Phmeter(room: this as Room, mqttId: componentId);

      case 'reservoir_meter':
      case 'netuno':
      case 'reservoir':
      case 'reservoir-meter':
        return reservoirMeter ??=
            ReservoirMeter(room: this as Room, mqttId: componentId);

      case 'light_sensor':
      case 'light':
      case 'light-sensor':
        return lightSensor ??=
            LightSensor(room: this as Room, mqttId: componentId);

      case 'daytime':
        return daytime ??= Daytime(room: this as Room, mqttId: componentId);

      case 'ebbflow':
        return ebbflow ??= Ebbflow(room: this as Room, mqttId: componentId);

      case 'interval_irrigation':
      case 'interval-irrigation':
        return intervalIrrigation ??=
            IntervalIrrigation(room: this as Room, mqttId: componentId);

      case 'ebbflow_flood':
      case 'ebbflow-flood-relay':
      case 'ebbflow-flood':
        return ebbflowFlood ??=
            EbbflowFlood(room: this as Room, mqttId: componentId);

      case 'ebbflow_drain':
      case 'ebbflow-drain-relay':
      case 'ebbflow-drain':
        return ebbflowDrain ??=
            EbbflowDrain(room: this as Room, mqttId: componentId);

      case 'reservoir_fill':
      case 'reservoir-fill-relay':
      case 'reservoir-fill':
        return reservoirFill ??=
            ReservoirFill(room: this as Room, mqttId: componentId);

      case 'reservoir_drain':
      case 'reservoir-drain-relay':
      case 'reservoir-drain':
        return reservoirDrain ??=
            ReservoirDrain(room: this as Room, mqttId: componentId);

      case 'lighting':
      case 'light-relay':
        return lighting ??= Lighting(room: this as Room, mqttId: componentId);

      case 'exaust':
      case 'exaust-relay':
        return exaust ??= Exaust(room: this as Room, mqttId: componentId);

      case 'humidifier':
      case 'humidifier-relay':
        return humidifier ??=
            Humidifier(room: this as Room, mqttId: componentId);

      case 'dehumidifier':
      case 'dehumidifier-relay':
        return dehumidifier ??=
            Dehumidifier(room: this as Room, mqttId: componentId);

      case 'humidifier_vpd':
      case 'humidifier-vpd':
        return humidifierVpd ??=
            HumidifierVpd(room: this as Room, mqttId: componentId);

      case 'dehumidifier_vpd':
      case 'dehumidifier-vpd':
        return dehumidifierVpd ??=
            DehumidifierVpd(room: this as Room, mqttId: componentId);

      case 'air_conditioner':
      case 'air-conditioner-relay':
      case 'air-conditioner':
        return airConditioner ??=
            AirConditioner(room: this as Room, mqttId: componentId);

      case 'co2_emitter':
      case 'co2-emitter':
        return co2Emitter ??=
            Co2Emitter(room: this as Room, mqttId: componentId);

      default:
        throw UnknownComponentError(componentId);
    }
  }

  // removeComponent
  Component? removeComponent(String componentId) {
    late final Component? component;
    switch (componentId) {
      case 'thermometer':
      case 'temperature':
        component = thermometer;
        thermometer = null;
        break;

      case 'hygrometer':
      case 'humidity':
        component = hygrometer;
        hygrometer = null;
        break;

      case 'vpd_meter':
      case 'vpd-meter':
        component = vpdMeter;
        vpdMeter = null;
        break;

      case 'co2_meter':
      case 'co2-meter':
        component = co2Meter;
        co2Meter = null;
        break;

      case 'phmeter':
        component = phmeter;
        phmeter = null;
        break;

      case 'reservoir_meter':
      case 'netuno':
      case 'reservoir':
      case 'reservoir-meter':
        component = reservoirMeter;
        reservoirMeter = null;
        break;

      case 'light_sensor':
      case 'light':
      case 'light-sensor':
        component = lightSensor;
        lightSensor = null;
        break;

      case 'daytime':
        component = daytime;
        daytime = null;
        break;

      case 'ebbflow':
        component = ebbflow;
        ebbflow = null;
        break;

      case 'interval_irrigation':
      case 'interval-irrigation':
        component = intervalIrrigation;
        intervalIrrigation = null;
        break;

      case 'ebbflow_flood':
      case 'ebbflow-flood-relay':
      case 'ebbflow-flood':
        component = ebbflowFlood;
        ebbflowFlood = null;
        break;

      case 'ebbflow_drain':
      case 'ebbflow-drain-relay':
      case 'ebbflow-drain':
        component = ebbflowDrain;
        ebbflowDrain = null;
        break;

      case 'reservoir_fill':
      case 'reservoir-fill-relay':
      case 'reservoir-fill':
        component = reservoirFill;
        reservoirFill = null;
        break;

      case 'reservoir_drain':
      case 'reservoir-drain-relay':
      case 'reservoir-drain':
        component = reservoirDrain;
        reservoirDrain = null;
        break;

      case 'lighting':
      case 'light-relay':
        component = lighting;
        lighting = null;
        break;

      case 'exaust':
      case 'exaust-relay':
        component = exaust;
        exaust = null;
        break;

      case 'humidifier':
      case 'humidifier-relay':
        component = humidifier;
        humidifier = null;
        break;

      case 'dehumidifier':
      case 'dehumidifier-relay':
        component = dehumidifier;
        dehumidifier = null;
        break;

      case 'humidifier_vpd':
      case 'humidifier-vpd':
        component = humidifierVpd;
        humidifierVpd = null;
        break;

      case 'dehumidifier_vpd':
      case 'dehumidifier-vpd':
        component = dehumidifierVpd;
        dehumidifierVpd = null;
        break;

      case 'air_conditioner':
      case 'air-conditioner-relay':
      case 'air-conditioner':
        component = airConditioner;
        airConditioner = null;
        break;

      case 'co2_emitter':
      case 'co2-emitter':
        component = co2Emitter;
        co2Emitter = null;
        break;

      default:
        throw UnknownComponentError(componentId);
    }
    return component;
  }
}
