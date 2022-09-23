import 'dart:async';

import 'package:async/async.dart';
import 'package:florafi/src/communicator.dart';
import 'package:florafi/src/mqtt_communicator.dart';
import 'package:logging/logging.dart';
import 'cloud.dart';
import 'events.dart';
import 'farm.dart';

typedef OnFarmCallback = void Function(Farm);

final _log = Logger("Florafi");

class Florafi {
  Farm joinFarm(FarmTicket ticket,
      {bool browserClient = false, bool secure = true}) {
    final communicator = MqttCommunicator(
      server: ticket.host,
      secure: secure,
      port: browserClient
          ? ticket.wssPort
          : secure
              ? ticket.tlsPort
              : ticket.port,
      username: ticket.username,
      password: ticket.password,
    );

    final farm = Farm(
      name: ticket.farmName,
      id: ticket.farmId,
      communicator: communicator,
      isReadOnly: ticket.isReadOnly,
    );

    return farm;
  }

  Future<MqttCommunicator> connect({
    required String host,
    port = 1883,
    secure = false,
    String? username,
    String? password,
  }) async {
    final communicator = MqttCommunicator(
      server: host,
      port: port,
      username: username,
      password: password,
      secure: secure,
    );

    await communicator.connect();
    return communicator;
  }

  final StreamGroup<FarmEvent> _events = StreamGroup<FarmEvent>.broadcast();

  Stream<FarmEvent> get events {
    return _events.stream;
  }

  final Map<int, Farm> farms = {};

  // StreamSubscription<FarmMessage>? _communicatorSubscription;

  StreamSubscription<FarmMessage> readFarms({
    required Communicator communicator,
    String baseTopic = "farm",
    OnFarmCallback? onFarm,
  }) {
    if (!baseTopic.endsWith("/")) baseTopic = "$baseTopic/";

    // process farm messages
    return communicator.messages.listen((message) {
      // validate topic
      String topic = message.topic;

      if (!topic.startsWith(baseTopic)) {
        _log.info(
            "ignoring message not on baseTopic '$baseTopic' (${message.topic})");
        return;
      }

      topic = topic.substring(baseTopic.length);
      final subtopics = topic.split("/");

      // get farm
      if (subtopics.length < 4) {
        _log.warning("received message with invalid topic (${message.topic})");
        return;
      }

      final farmId = int.tryParse(subtopics.removeAt(0));
      if (farmId == null) {
        _log.warning(
            "received message with invalid farm id (${message.topic})");
        return;
      }

      if (!farms.containsKey(farmId)) {
        farms[farmId] = Farm(name: "Farm $farmId", id: farmId);
        _events.add(farms[farmId]!.events);
      }

      // process message
      message.topic = subtopics.join("/");
      farms[farmId]!.processMessage(message);
    });
  }
}
