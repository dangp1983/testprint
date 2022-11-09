import 'dart:typed_data';
import 'dart:ui';
import 'package:blue_thermal_printer_example/print_database.dart';
import 'package:blue_thermal_printer_example/toast_util.dart';
import 'package:flutter/foundation.dart';
import 'package:blue_thermal_printer_example/printerenum.dart';
import 'package:image/image.dart' as im;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';



class PrintUtils {
  List<BluetoothDevice> _devices = [];
  BlueThermalPrinter bluetoothPrint = BlueThermalPrinter.instance;
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  printData() async {


    bluetooth.isConnected.then((isConnected) {




      if (isConnected == true) {


      }
    });




    try {
      await bluetooth.isConnected.then((isConnected) async {
        List<Uint8List> imgList = [];
        Uint8List imageInt = await getBillImage(
            "លេខសំបុត្រ : 123455\n"
                "ថ្ងៃទី : ១២ មីថុនា ២០២២\n"
                "សរុប : 1000៛\n\n\n"
        );
        im.Image? receiptImg = im.decodePng(imageInt);

        for (var i = 0; i <= receiptImg!.height; i += 200) {
          im.Image cropedReceiptImg = im.copyCrop(receiptImg, 0, i, 470, 200);
          Uint8List bytes = im.encodePng(cropedReceiptImg) as Uint8List;
          imgList.add(bytes);
        }

        for (var element in imgList) {
          bluetoothPrint.printImageBytes(element);
        }
      });
    } catch (ex) {
      if (kDebugMode) {
        print("Error = $ex");
      }
    }
  }

  Future<Uint8List> getBillImage(String label,
      {double fontSize = 26, FontWeight fontWeight = FontWeight.w500}) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    /// Background
    final backgroundPaint = Paint()..color = Colors.white;
    const backgroundRect = Rect.fromLTRB(372, 10000, 0, 0);
    final backgroundPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(backgroundRect, const Radius.circular(0)),
      )
      ..close();
    canvas.drawPath(backgroundPath, backgroundPaint);

    //Title
    final ticketNum = TextPainter(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.left,
      text: TextSpan(
          text: label,
          style: TextStyle(
              color: Colors.black, fontSize: fontSize, fontWeight: fontWeight)),
    );
    ticketNum
      ..layout(
        maxWidth: 372,
      )
      ..paint(
        canvas,
        const Offset(0, 0),
      );

    canvas.restore();
    final picture = recorder.endRecording();
    final pngBytes = await (await picture.toImage(372.toInt(), ticketNum.height.toInt() + 5))
            .toByteData(format: ImageByteFormat.png);
    return pngBytes!.buffer.asUint8List();
  }



  _checkListDeviceAvailable({ required Function() connected}) async {
    await _scanDevices();
    if (_devices.isNotEmpty) {
      String? deviceAddress = await getDeviceAddress();
      if (deviceAddress!.isNotEmpty) {
        for (int i = 0; i < _devices.length; i++) {
          if (deviceAddress == _devices[i].address) {
            try{
              await bluetoothPrint.disconnect();
            }catch(ex){}
            await bluetoothPrint.connect(_devices[i]);
            connected();
          }
        }
      }
    }
  }

  _scanDevices() async {
    try {
      _devices = await bluetoothPrint.getBondedDevices();
    } on PlatformException {
      if (kDebugMode) {
        print("Error no prepare devices founds.");
      }
    }
  }

}
