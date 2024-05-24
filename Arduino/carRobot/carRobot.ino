#include <ArduinoBLE.h>

BLEService carService("f0dd0982-91fd-49ea-afd1-1b60881df9c1"); // Bluetooth® Low Energy LED Service

// Bluetooth® Low Energy LED Switch Characteristic - custom 128-bit UUID, read and writable by central
BLEByteCharacteristic switchCharacteristic("9e690001-af6e-4678-b4aa-918855503f62", BLERead | BLEWrite);
BLEByteCharacteristic motionCharacteristic("9e690002-af6e-4678-b4aa-918855503f62", BLERead | BLEWrite);
BLEByteCharacteristic speedCharacteristic("9e690003-af6e-4678-b4aa-918855503f62", BLERead | BLEWrite);
BLEByteCharacteristic readCharacteristic("9e690004-af6e-4678-b4aa-918855503f62", BLERead | BLENotify);

const int ledPin = LED_BUILTIN; // pin to use for the LED
uint8_t counter = 0;

typedef enum motionCommands{
  STOP = 0x0A,
  MOVE_FRONT = 0x08,
  MOVE_BACK = 0x02,
  MOVE_LEFT = 0x04,
  MOVE_RIGHT = 0x06
};

void setup() {
  Serial.begin(9600);
  while (!Serial);

  pinMode(ledPin, OUTPUT); // set LED pin to output mode

  // begin initialization
  if (!BLE.begin()) {
    Serial.println("starting Bluetooth® Low Energy module failed!");

    while (1);
  }

  // set advertised local name and service UUID:
  BLE.setLocalName("carRobot");
  BLE.setAdvertisedService(carService);

  // add the characteristic to the service
  carService.addCharacteristic(switchCharacteristic);
  carService.addCharacteristic(motionCharacteristic);
  carService.addCharacteristic(speedCharacteristic);
  carService.addCharacteristic(readCharacteristic);

  // add service
  BLE.addService(carService);

  // set the initial value for the characeristic:
  switchCharacteristic.writeValue(0);
  motionCharacteristic.writeValue(0x0A); // Init to STOP
  speedCharacteristic.writeValue(100);
  readCharacteristic.writeValue(0);

  // start advertising
  BLE.advertise();

  Serial.println("Bluetooth® device active, waiting for connections...");
}

void ledControl() {
  // if the remote device wrote to the characteristic,
  // use the value to control the LED:
  if (switchCharacteristic.written()) {
    if (switchCharacteristic.value()) {   // any value other than 0
      Serial.println("LED on");
      digitalWrite(ledPin, HIGH);         // will turn the LED on
    } else {                              // a 0 value
      Serial.println(F("LED off"));
      digitalWrite(ledPin, LOW);          // will turn the LED off
    }
  }
}

void motionControl(){
  // if the remote device wrote to the characteristic,
  // use the value to control the motor:
  if (motionCharacteristic.written()) {
    switch(motionCharacteristic.value()){
      case MOVE_BACK: Serial.println("BACK"); break;
      case MOVE_LEFT: Serial.println("LEFT"); break;
      case MOVE_RIGHT: Serial.println("RIGHT"); break;
      case MOVE_FRONT: Serial.println("FRONT"); break;
      case STOP: Serial.println("STOP"); break;
      default: break; // Do nothing
    }
  }
}

void speedControl(){
  // if the remote device wrote to the characteristic,
  // use the value to control the motor:
  if (speedCharacteristic.written()) {
    Serial.print("Speed : ");
    Serial.println(speedCharacteristic.value());
  }
}

void notifHandler() {
  // read the current led pin state
  if (digitalRead(ledPin) == HIGH)
  {
    // Notify
    if(readCharacteristic.writeValue(counter) == 1)
    {
      Serial.print("Notified : ");
      Serial.println(counter);
    }

    if(counter < 255) {
      counter ++;
    } else {
      counter = 0;
    }

    // Wait 1 sec
    delay(1000);
  }
}

void loop() {
  // listen for Bluetooth® Low Energy peripherals to connect:
  BLEDevice central = BLE.central();

  // if a central is connected to peripheral:
  if (central) {
    Serial.print("Connected to central: ");
    // print the central's MAC address:
    Serial.println(central.address());

    // while the central is still connected to peripheral:
    while (central.connected()) {
      ledControl();
      motionControl();
      speedControl();
      notifHandler();
    }

    // when the central disconnects, print it out:
    Serial.print(F("Disconnected from central: "));
    Serial.println(central.address());
  }
}
