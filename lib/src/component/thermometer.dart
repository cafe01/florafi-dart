import '../room.dart';
import 'component.dart';

class Thermometer extends Component with Sensor {
  Thermometer(Room room) : super(room: room) {
    name = "Termômetro";
    measurementName = "Temperatura";
  }

  int? get lastValue => getInt("last_value");
  int? get lowTemperatureLimit => getInt("low_temperature_limit");
  int? get highTemperatureLimit => getInt("high_temperature_limit");

  set lowTemperatureLimit(int? value) =>
      setControl("low_temperature_limit", value);
  set highTemperatureLimit(int? value) =>
      setControl("high_temperature_limit", value);
}
