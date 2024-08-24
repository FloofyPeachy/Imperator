import 'package:animate_gradient/animate_gradient.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:imperator_desktop/core/config.dart';
import 'package:imperator_desktop/core/cv/analyser.dart';
import 'package:imperator_desktop/core/cv/processors.dart';
import 'package:imperator_desktop/live/obs.dart';
import 'package:obs_websocket/obs_websocket.dart';
import 'package:validator_regex/validator_regex.dart';

class LivePage extends StatefulWidget {
  const LivePage();

  @override
  State<StatefulWidget> createState() => _LivePage();
}

class _LivePage extends State<LivePage> with TickerProviderStateMixin {
  FrameProcessor? processor;
  OBSConnection obs = OBSConnection();
  final _formKey = GlobalKey<FormState>();
  List<TextEditingController> myController = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController()
  ];

  @override
  void initState() {
    super.initState();

    if (Config.get("live/ip_address") == "" || Config.get("live/port") == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("OBS Configuration"),
                content: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          "Let's set your OBS configuration. You can change this in the settings later."),
                      Text(
                          "This uses OBS's websocket feature. To configure it, go to Tools -> WebSockets Server Settings."),
                      TextFormField(
                        controller: myController[0],
                        decoration: const InputDecoration(
                          labelText: "IP Address",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          }
                          if (Validator.ipAddress(value) == false) {
                            return 'You gotta enter a valid IP address';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: myController[1],
                        decoration: const InputDecoration(
                          labelText: "Port",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          }
                          if (Validator.digits(value) == false) {
                            return 'You gotta enter a valid port';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: myController[2],
                        decoration: const InputDecoration(
                          labelText: "Password",
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Config.set("live/ip_address", myController[0].text);
                            Config.set(
                                "live/port", int.parse(myController[1].text));
                            Config.set("live/password", myController[2].text);
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text("Save"),
                      )
                    ],
                  ),
                ),
              );
            },
            barrierDismissible: false);
      });
    }
    obs.connect().then((value) {
      obs.startCapture();
    }).onError((error, stackTrace) {
      print("Error connecting to OBS: $error");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Couldn't connect to OBS: $error"),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: "Try again",
          onPressed: () {
            //obs.connect();
          },
        ),

      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Live"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(obs.connected == 0 ? "Not connected" : obs.connected == 1 ? "Connected" : "Connecting...", style: TextStyle(fontSize: 22, color: obs.connected == 0 ? Colors.red : obs.connected == 1 ? Colors.green : Colors.yellow),),

                      OutlinedButton(
                        onPressed: () {
                          obs.connect();
                        },
                        child: const Text("Reconnect"),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          obs.startCapture();
                        },
                        child: const Text("Start Capture"),
                      ),
                      Divider(),
                      Row(
                        children: [
                          Text("Source: ", style: TextStyle(fontSize: 16),),
                          FutureBuilder<List<SceneItemDetail>>(
                            future: obs.getSources(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done) {
                                List<SceneItemDetail> sources = snapshot.data!;
                                print(snapshot.data);
                                return DropdownMenu<String>(
                                  initialSelection: obs.sceneItem,
                                  dropdownMenuEntries: sources.map<DropdownMenuEntry<String>>((SceneItemDetail value) {
                                    return DropdownMenuEntry<String>(value: value.sourceName, label: value.sourceName);
                                  }).toList(),
                                  onSelected: (String? value) {
                                    obs.sceneItem = value;
                                  },
                                );
                              }
                              if (snapshot.hasError) {
                                return Text("Couldn't get sources: ${snapshot.error}");
                              }
                              return const SpinKitThreeBounce(color: Colors.blue, size: 20,);
                            }
                          ),
                        ],
                      ),

                      /*DropdownButton<String>(
                        items: obs.source!.
                            .map((source) => DropdownMenuItem<String>(
                          value: source.name,
                          child: Text(source.name),
                        ))
                            .toList(),
                        onChanged: (String? value) {
                          setState(() {
                            obs.sourceName = value;
                          });
                        },
                        value: obs.sourceName,
                      ),*/
                    ],


                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Imperator Live", style: TextStyle(fontSize: 26),),
                        Text("Imperator is currently watching " + obs.sceneItem! + " and looking for gameplay.", style: TextStyle(fontSize: 16),),
                        Text("When it finds some, it'll record it.", style: TextStyle(fontSize: 16),),
                        Divider(),
                        StreamBuilder(
                          stream: obs.gameplayStream.stream,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              var data = snapshot.data;
                              return buildStateCard(data!.$1);
                            }
                            return buildStateCard(GameplayStates.UNKNOWN);
                          },
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],

          ),
        ));
  }

  Widget buildStateCard(GameplayStates state) {
    return Card(
      color: Colors.transparent,
      child: AnimateGradient(
        duration: Duration(seconds: 2),
        reverse: true,
        primaryColors: state == GameplayStates.GAMEPLAY ? [
            Colors.red.withOpacity(0.2),
            Colors.pinkAccent.withOpacity(0.2),
          ] : [
            Colors.transparent,
            Colors.transparent,
          ],
        secondaryColors: state == GameplayStates.GAMEPLAY ?  [
            Colors.blueAccent.withOpacity(0.2),
            Colors.blue.withOpacity(0.2),
          ] : [
          Colors.transparent,
          Colors.transparent,
          ],
        child: ListTile(
        title: Text("State: $state"),
        leading: Icon(state == GameplayStates.GAMEPLAY ? Icons.fiber_manual_record : Icons.camera),
        subtitle: Text(state == GameplayStates.GAMEPLAY ? "Gameplay detected. Get that high score!!" : "No gameplay detected just yet.. start a song!"),
      ),
      ),
    );

  }
}
