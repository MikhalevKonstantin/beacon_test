import 'dart:async';
import 'dart:io';

import 'package:beacons_plugin/beacons_plugin.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class BeaconTesting extends StatefulWidget {
  // const BeaconTesting({Key key}) : super(key: key);

  @override
  _BeaconTestingState createState() => _BeaconTestingState();
}

class _BeaconTestingState extends State<BeaconTesting> {
  String _beaconResult = 'Not Scanned Yet.';
  int _nrMessagesReceived = 0;
  bool isRunning = false;
  bool isFirstTime = true;
  List<String> _results = [];

  final ScrollController _scrollController = ScrollController();

  final StreamController<String> beaconEventsController =
      StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    beaconEventsController.close();
    BeaconsPlugin.clearDisclosureDialogShowFlag(false);
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (Platform.isAndroid) {
      await BeaconsPlugin.setDisclosureDialogMessage(
          title: 'Background Locations',
          message: 'You have to enable the required permission');
      await _requestBluetoothPermissions();
    }

    beaconEventsController.stream.listen(
        (data) {
          if (data.isNotEmpty && isRunning) {
            setState(() {
              _beaconResult = data;
              _results.add(_beaconResult);
              _nrMessagesReceived++;
            });
          }
        },
        onDone: () {},
        onError: (error) {
          print("Error: $error");
        });
  }

  Future<void> _requestBluetoothPermissions() async {
    // Запрос разрешений для Android 12 и выше
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.bluetoothAdvertise.request().isGranted &&
        await Permission.location.request().isGranted) {
      print("Bluetooth and Location permissions granted");
    } else {
      print("Permissions denied");
    }
  }

  Future<void> runPlugin() async {
    if (isFirstTime) {
      BeaconsPlugin.listenToBeacons(beaconEventsController);
      if (Platform.isAndroid) {
        BeaconsPlugin.addRegion(
            'MyBeacon1', '2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6');
        BeaconsPlugin.addRegion(
            'MyBeacon2', '2F234454-CF6D-4A0F-ADF2-F4911BA9FFA7');
      }
      if (Platform.isIOS) {
        BeaconsPlugin.addRegionForIOS(
            '2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6', 1, 1, 'MyBeacon1');
        BeaconsPlugin.addRegionForIOS(
            '2F234454-CF6D-4A0F-ADF2-F4911BA9FFA7', 1, 2, 'MyBeacon2');
      }
      isFirstTime = false;
    } else {
      BeaconsPlugin.listenToBeacons(beaconEventsController);
    }
    setState(() {
      isRunning = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Monitoring Beacons'),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                  child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Total Results: $_nrMessagesReceived',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF22369C),
                      fontWeight: FontWeight.bold,
                    )),
              )),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (isRunning) {
                      await BeaconsPlugin.stopMonitoring();
                      setState(() {
                        isRunning = false;
                      });
                    } else {
                      await runPlugin();
                      await BeaconsPlugin.startMonitoring();
                    }
                  },
                  child: Text(isRunning ? 'Stop Scanning' : 'Start Scanning',
                      style: TextStyle(fontSize: 20)),
                ),
              ),
              Visibility(
                visible: _results.isNotEmpty,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _nrMessagesReceived = 0;
                        _results.clear();
                      });
                    },
                    child:
                        Text("Clear Results", style: TextStyle(fontSize: 20)),
                  ),
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              Expanded(child: _buildResultsList())
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return Scrollbar(
      thumbVisibility: true,
      controller: _scrollController,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        physics: ScrollPhysics(),
        controller: _scrollController,
        itemCount: _results.length,
        separatorBuilder: (BuildContext context, int index) => Divider(
          height: 1,
          color: Colors.black,
        ),
        itemBuilder: (context, index) {
          DateTime now = DateTime.now();
          String formattedDate =
              DateFormat('yyyy-MM-dd – kk:mm:ss.SSS').format(now);
          final item = ListTile(
              title: Text(
                "Time: $formattedDate\n${_results[index]}",
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF1A1B26),
                  fontWeight: FontWeight.normal,
                ),
              ),
              onTap: () {});
          return item;
        },
      ),
    );
  }
}
