import 'package:digital_lcd_number/digital_lcd_number.dart';
import 'package:flutter/material.dart';

class DigitalLcd extends StatefulWidget {
  const DigitalLcd({super.key, required this.value});

  final List<int> value;

  @override
  State<StatefulWidget> createState() {
    return _DigitalLcdState();
  }
}

class _DigitalLcdState extends State<DigitalLcd> {
  get _lastValue => widget.value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      // width: 100,
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Row(
          children: [
            DigitalLcdNumber(
              number: (_lastValue[0] ~/ 10) % 10, // 1st digit
              color: Colors.red,
            ),
            DigitalLcdNumber(
              number: _lastValue[0] % 10, // 2nd digit
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
