part of '../room.dart';

extension RoomComponents on Room {
  Thermometer? get thermometer => getComponentByType<Thermometer>();
  Hygrometer? get hygrometer => getComponentByType<Hygrometer>();
  VpdMeter? get vpdMeter => getComponentByType<VpdMeter>();
  Co2Meter? get co2Meter => getComponentByType<Co2Meter>();
  PhMeter? get phMeter => getComponentByType<PhMeter>();
  ReservoirMeter? get reservoirMeter => getComponentByType<ReservoirMeter>();
  LightSensor? get lightSensor => getComponentByType<LightSensor>();
  Daytime? get daytime => getComponentByType<Daytime>();
  Ebbflow? get ebbflow => getComponentByType<Ebbflow>();
  IntervalIrrigation? get intervalIrrigation =>
      getComponentByType<IntervalIrrigation>();
  EbbflowFlood? get ebbflowFlood => getComponentByType<EbbflowFlood>();
  EbbflowDrain? get ebbflowDrain => getComponentByType<EbbflowDrain>();
  ReservoirFill? get reservoirFill => getComponentByType<ReservoirFill>();
  ReservoirDrain? get reservoirDrain => getComponentByType<ReservoirDrain>();
  Lighting? get lighting => getComponentByType<Lighting>();
  Exaust? get exaust => getComponentByType<Exaust>();
  Humidifier? get humidifier => getComponentByType<Humidifier>();
  Dehumidifier? get dehumidifier => getComponentByType<Dehumidifier>();
  HumidifierVpd? get humidifierVpd => getComponentByType<HumidifierVpd>();
  DehumidifierVpd? get dehumidifierVpd => getComponentByType<DehumidifierVpd>();
  AirConditioner? get airConditioner => getComponentByType<AirConditioner>();
  Heater? get heater => getComponentByType<Heater>();
  Co2Emitter? get co2Emitter => getComponentByType<Co2Emitter>();
}
