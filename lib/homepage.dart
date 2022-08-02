import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_popup/internet_popup.dart';
import 'package:sizer/sizer.dart';

final internetConnectivityProvider = StateProvider<bool>((ref) => false);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final Isolate isolate;

  //receivePort of isolate 1
  ReceivePort receivePort1iso1 = ReceivePort();
  @override
  void initState() {
    InternetPopup().initialize(
        context: context,
        onTapPop: true,
        onChange: (value) {
          ref.read(internetConnectivityProvider.state).state = value;
        });
    startIsolate();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: 100.h,
        width: 100.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Consumer(builder: (context, ref, _) {
              bool isConnected = ref.watch(internetConnectivityProvider);

              if (isConnected == true) {
                print('isConnected $isConnected');

                return RichText(
                  text: const TextSpan(children: [
                    WidgetSpan(
                        child: Icon(
                      Icons.circle,
                      color: Colors.green,
                      size: 12,
                    )),
                    WidgetSpan(child: SizedBox(width: 0.5)),
                    WidgetSpan(
                        child: Text(
                      'Online',
                      style: TextStyle(color: Colors.green),
                    )),
                  ]),
                );
              } else {
                return RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(children: [
                    WidgetSpan(
                        child: Icon(
                      Icons.circle,
                      color: Colors.red,
                      size: 12,
                    )),
                    WidgetSpan(child: SizedBox(width: 0.5)),
                    WidgetSpan(
                        child: Text(
                      'Offline',
                      style: TextStyle(color: Colors.red),
                    )),
                  ]),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  void startIsolate() async {
    try {
      //started the isolate
      Isolate isolate = await Isolate.spawn<IsolateModel>(isolateFunction, IsolateModel(5, receivePort1iso1.sendPort));
      print('started the isolate');

      //sendport of isolate2
      SendPort sendPortIso2;
      print('sendport of isolate2');

      receivePort1iso1.listen((message) async {
        print('message recieved ${message.runtimeType}');
        if (message.runtimeType != String) {
          sendPortIso2 = message;
          //sending first message
          sendPortIso2.send({'name': 'dew', 'age': 28});
          print('sending first message');
          await Future.delayed(const Duration(seconds: 3), () {
            sendPortIso2.send('start');
          });
        } else {
          if (message == 'done') {
            print('done');
          } else {
            isolate.kill();
            print('stop');
          }
        }
      });
    } catch (e, s) {
      print('catch $s');
    }
  }
}

void isolateFunction(IsolateModel model) async {
  //receivePost of isolate 2
  ReceivePort receivePortIso2 = ReceivePort();
  print('receivePost of isolate 2');

  //sendPort of isolate 1
  SendPort sendPortIso1 = model.sendPort;
  print('sendPort of isolate 1');

  //sending sendport of isolate2 through isolate 1 sendport
  sendPortIso1.send(receivePortIso2.sendPort);
  print('sending sendport of isolate2 through isolate 1 sendport');

  receivePortIso2.listen((message) async {
    print('got the message $message');
    if (message == 'start') {
      print('started the loop');
      int i = 0;
      while (i < model.count) {
        await Future.delayed(const Duration(seconds: 3), () {
          print('isolate print $i');
        });

        if (i == model.count - 1) {
          sendPortIso1.send('done');
        }
        i++;
      }
    } else {
      sendPortIso1.send('stop');
    }
  });
}

class IsolateModel {
  final int count;
  final SendPort sendPort;

  IsolateModel(this.count, this.sendPort);
}
