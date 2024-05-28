import 'dart:async';

import 'package:flutter/material.dart';
import 'package:car_robot/utils/snackbar.dart';
import 'package:car_robot/widgets/custom_slider.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:car_robot/widgets/digital_lcd.dart';

const switchCharacteristicIndex = 1;
const motionCharacteristicIndex = 2;
const speedCharacteristicIndex = 3;
const luxCharacteristicIndex = 4;

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  // UI variables
  double speed = 127;
  String color = 'red';
  String ledImg = 'assets/images/led_off.png';
  List<int> _luxSensorValue = [0];
  // Bluetooth variables
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isLegobotDetected = false;
  ScanResult? _legobot;
  late StreamSubscription<List<int>> _lastValueSubscription;

  @override
  void initState() {
    super.initState();

    FlutterBluePlus.scanResults.listen((results) {
      if (results.isNotEmpty) {
        if (results.last.advertisementData.advName == "carRobot") {
          _isLegobotDetected = true;
          _legobot = results.last;
          onDeviceDetected();
          // Subscribe to connection state
          _legobot!.device.connectionState.listen((state) async {
            _connectionState = state;
            if (mounted) {
              setState(() {});
            }
          });
        }
      }
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {
      Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
  }

  @override
  void dispose() {
    _lastValueSubscription.cancel();
    super.dispose();
  }

  // Getters
  bool get _isLegobotConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  BluetoothCharacteristic getCharacteristic(int charIndex) {
    if (_services.isEmpty) {
      Snackbar.show(ABC.c, "No services found", success: false);
    } else {
      for (var service in _services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid ==
              Guid(
                  "9e69000${charIndex.toString()}-af6e-4678-b4aa-918855503f62")) {
            return characteristic;
          }
        }
      }
    }
    throw Exception("Characteristic not found");
  }

  // Actions
  Future onConnectPressed(BluetoothDevice device) async {
    await device.connect().catchError((e) {
      Snackbar.show(ABC.b, prettyException("Connect Error:", e),
          success: false);
    });
    if (mounted) {
      setState(() {
        onDiscoverServicesPressed(device)
            .then((value) => print("Discover Services Success"));
      });
    }
  }

  Future onDisconnectPressed(BluetoothDevice device) async {
    await device.disconnect().catchError((e) {
      Snackbar.show(ABC.b, prettyException("Connect Error:", e),
          success: false);
    });
    if (mounted) {
      setState(() {});
    }
  }

  Future onDiscoverServicesPressed(BluetoothDevice device) async {
    try {
      _services = await device.discoverServices();
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Discover Services Error:", e),
          success: false);
    }
    if (mounted) {
      setState(() {
        onSubscribePressed(luxCharacteristicIndex);
      });
    }
  }

  Future onSubscribePressed(int characteristic_index) async {
    try {
      // Subscribe to characteristic
      _lastValueSubscription = getCharacteristic(characteristic_index)
          .onValueReceived
          .listen((value) {
        _luxSensorValue = value;
        if (mounted) {
          setState(() {});
        }
      });
      // Enable notifications
      await getCharacteristic(characteristic_index).setNotifyValue(true);
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Subscribe Error:", e),
          success: false);
    }
  }

  Future onWritePressed(List<int> value, int characteristic_index) async {
    try {
      await getCharacteristic(characteristic_index).write(value,
          withoutResponse: getCharacteristic(characteristic_index)
              .properties
              .writeWithoutResponse);
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Write Error:", e), success: false);
    }
  }

  Future onRefreshPressed() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e),
          success: false);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onDeviceDetected() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e),
          success: false);
    }
    if (mounted) {
      setState(() {});
    }
  }

  // Widgets
  Widget _buildConnectButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
      ),
      onPressed: (_isLegobotDetected)
          ? () => _isLegobotConnected
              ? onDisconnectPressed(_legobot!.device)
              : onConnectPressed(_legobot!.device)
          : null,
      child: _isLegobotConnected
          ? const Text('DECONNECTER')
          : const Text('CONNECTER'),
    );
  }

  Widget _directionButton(IconData icon, int directionValue) {
    return IconButton(
      onPressed: () {
        onWritePressed([directionValue], motionCharacteristicIndex);
      },
      icon: Icon(icon, size: 50),
    );
  }

  Widget _speedControl() {
    return Column(
      children: [
        const Text(
          "VITESSE",
          style: TextStyle(fontSize: 30, fontFamily: "LegoFilled"),
          textAlign: TextAlign.left,
        ),
        const SizedBox(
          height: 20,
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: CustomSliderThumb(
              thumbRadius: 20,
              sliderValue: (speed / 255) * 100,
            ),
            activeTrackColor: Theme.of(context).colorScheme.onErrorContainer,
            inactiveTrackColor: Theme.of(context).colorScheme.errorContainer,
            thumbColor: Theme.of(context).colorScheme.error,
          ),
          child: Slider(
            value: (speed / 255) * 100,
            max: 100,
            min: 0,
            onChanged: (double value) {
              setState(() {
                speed = (value / 100) * 255;
              });
            },
            onChangeEnd: (double value) {
              onWritePressed([speed.toInt()], speedCharacteristicIndex);
            },
          ),
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }

  Widget _joystickControl() {
    return SafeArea(
      child: Stack(
        children: [
          Align(
            // alignment: const Alignment(0, 0.2),
            child: Joystick(
              mode: JoystickMode.horizontalAndVertical,
              stick: Image.asset(
                'assets/images/flash_mcqueen.jpg',
                width: 90,
              ),
              listener: (details) {
                setState(() {
                  if (details.x > 0) {
                    onWritePressed([0x06], motionCharacteristicIndex);
                  } else if (details.x < 0) {
                    onWritePressed([0x04], motionCharacteristicIndex);
                  }

                  if (details.y > 0) {
                    onWritePressed([0x02], motionCharacteristicIndex);
                  } else if (details.y < 0) {
                    onWritePressed([0x08], motionCharacteristicIndex);
                  }
                });
              },
              // Send STOP command when the joystick is released
              onStickDragEnd: () {
                onWritePressed([0x0A], motionCharacteristicIndex);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _ledButton() {
    return AnimatedContainer(
      // alignment: const Alignment(0, 0.8),
      duration: const Duration(seconds: 0),
      curve: Curves.linear,
      child: Material(
        shape: const CircleBorder(),
        child: InkWell(
          child: Image.asset(
            ledImg,
            width: 80,
          ),
          onTap: () {
            setState(() {
              if (ledImg == 'assets/images/led_off.png') {
                // led on
                onWritePressed([0x01], switchCharacteristicIndex);
                ledImg = 'assets/images/blue_led_on.png';
              } else {
                // led off
                onWritePressed([0x00], switchCharacteristicIndex);
                ledImg = 'assets/images/led_off.png';
              }
            });
          },
        ),
      ),
    );
  }

  Widget _luxSensorOutput() {
    return Expanded(child: DigitalLcd(value: _luxSensorValue));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        title: Text(
          "CAR ROBOT",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontFamily: "LegoOutlined",
            fontSize: 30,
          ),
        ),
        actions: [_buildConnectButton(context)],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/legobot_background2.png"),
            fit: BoxFit.cover,
            opacity: 0.75,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 70),
            // Expanded(child: _gridControl()),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 100),
                _ledButton(),
                _luxSensorOutput(),
              ],
            ),
            Expanded(
              child: _joystickControl(),
            ),
            _speedControl(),
            const SizedBox(height: 110),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          onRefreshPressed();
        },
        tooltip: 'Refresh',
        child: const Icon(Icons.autorenew),
      ),
    );
  }
}
