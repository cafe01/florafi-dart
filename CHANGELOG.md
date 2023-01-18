## 0.10.1
  - fixed Florafi.readFarms() not calling onFarm callback

## 0.6.0
- added ReservoirMeter, ReservoirFill, ReservoirDrain

## 0.5.0
- new components: Co2Meter and Co2Emitter
- LogLine.time now defaults to local time
- modified Thermometer measurement unit from "º" to "ºC"

## 0.4.0
- added VpdMeter
- added HumidifierVpd
- added DehumidifierVpd

## 0.3.0
- improved component to device binding
- improved DayTimeExtension
- implemented EbbflowExtension
- LightSensor: changed measurement name
- MqttCommunicator: fixed client id
- Device: added reboot(), forget()
- added Phmter component


## 0.2.0
- FarmEvent: added fromRetainedMessage flag
- FloraCloud: implemented fluxQuery()
- FloraCloud: improved authentication
- Florafi: implemented connect() and readFarms()

## 0.1.1

- not emitting 'deviceState' event together with 'deviceStatus'

## 0.1.0

- Initial version.
