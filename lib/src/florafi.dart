import 'package:florafi/src/mqtt_communicator.dart';
import 'cloud.dart';
import 'farm.dart';

class Florafi {
  Farm joinFarm(FarmTicket ticket) {
    final communicator = MqttCommunicator(
        server: ticket.host,
        port: ticket.tlsPort,
        username: ticket.username,
        password: ticket.password);

    final farm = Farm(
        name: ticket.farmName, id: ticket.farmId, communicator: communicator);

    return farm;
  }
}
