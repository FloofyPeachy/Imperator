import 'dart:typed_data';

import 'package:animate_gradient/animate_gradient.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:imperator_desktop/core/config.dart';
import 'package:imperator_desktop/core/cv/analyser.dart';
import 'package:imperator_desktop/core/cv/processors.dart';
import 'package:imperator_desktop/core/util.dart';
import 'package:imperator_desktop/live/obs.dart';
import 'package:imperator_desktop/model/model.dart';
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
      //obs.startCapture();
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

                     ValueListenableBuilder<ObsConnectionState>(
                       valueListenable: obs.connectionState,
                       builder: (context, ObsConnectionState value, child) {
                         return Column(
                           children: [
                             SizedBox(
                                width: 200,
                               child: ListTile(
                                 title: Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     Container(
                                       width: 15,
                                       height: 15,
                                       decoration: BoxDecoration(
                                           color: value == ObsConnectionState.connected
                                               ? Colors.green
                                               : value == ObsConnectionState.disconnected
                                               ? Colors.red
                                               : value == ObsConnectionState.connecting
                                               ? Colors.yellow
                                               : value == ObsConnectionState.error
                                               ? Colors.red
                                               : Colors.grey,
                                           shape: BoxShape.circle
                                       ),
                                     ),
                                     SizedBox(width: dH(context) * 0.01,),
                                     Text(value == ObsConnectionState.connected
                                         ? "Connected"
                                         : value == ObsConnectionState.disconnected
                                         ? "Disconnected"
                                         : value == ObsConnectionState.connecting
                                         ? "Connecting"
                                         : value == ObsConnectionState.error
                                         ? "Error"
                                         : "Unknown State", style: const TextStyle(fontWeight: FontWeight.bold),),
                                   ],
                                 ),
                                 subtitle: Text("OBS: ${Config.get("live/ip_address")}:${Config.get("live/port")}"),

                               ),
                             ),
                             FilledButton(
                               onPressed: value == ObsConnectionState.connecting ? null : () {
                                 if (value == ObsConnectionState.connected) {
                                   obs.disconnect();
                                 } else {
                                   obs.connect();
                                 }
                               },
                               child: Text(value == ObsConnectionState.connected ? "Disconnect" : "Connect"),
                             ),
                             SizedBox(height: dH(context) * 0.01,),
                             value == ObsConnectionState.connected ? Column(
                               children: [
                                 Row(
                                   children: [
                                     Text("Source: ", style: TextStyle(fontSize: 16),),
                                     FutureBuilder<List<SceneItemDetail>>(
                                         future: obs.getSources(),
                                         builder: (context, snapshot) {
                                           if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                             List<SceneItemDetail> sources = snapshot.data!;
                                             print(snapshot.data);
                                             return DropdownMenu<String>(
                                               inputDecorationTheme: InputDecorationTheme(
                                                 isDense: true,
                                                 contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                                 constraints: BoxConstraints.tight(const
                                                 Size.fromHeight(40)),
                                                 border: OutlineInputBorder(
                                                   borderRadius: BorderRadius.circular(2),
                                                 ),
                                               ),
                                               initialSelection: obs.sceneItem.value,
                                               dropdownMenuEntries: sources.map<DropdownMenuEntry<String>>((SceneItemDetail value) {
                                                 return DropdownMenuEntry<String>(value: value.sourceName, label: value.sourceName);
                                               }).toList(),
                                               onSelected: (String? value) {
                                                 obs.sceneItem.value = value;
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
                                 SizedBox(height: dH(context) * 0.01,),
                                 FilledButton(
                                   onPressed: obs.sceneItem.value == null ? null : () {
                                     obs.startCapture();
                                   },
                                   child: Text("Start Capture"),
                                 ),
                               ],
                             ) : SizedBox(),
                           ],
                         );
                       },
                     ),
                      Divider(),


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
                    child: ValueListenableBuilder(
                      valueListenable: obs.isCapturing,
                      builder: (BuildContext context, bool value, Widget? child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Imperator Live", style: TextStyle(fontSize: 26),),
                            Text(value ? "Imperator is currently watching " + obs.sceneItem.value! + " and looking for gameplay." : 'Imperator isnt watching for gameplay right now. Click on "Start Capture" to start!!', style: TextStyle(fontSize: 16),),
                            value ? Text("When it finds some, it'll record it.", style: TextStyle(fontSize: 16),) : SizedBox(),
                            Divider(),
                            StreamBuilder(
                              stream: obs.gameplayStream.stream,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const SpinKitThreeBounce(color: Colors.blue, size: 20,);
                                }

                                GameplayStates state = snapshot.data!.$1;
                                List<Gameplay> gameplays = snapshot.data!.$2;
                                return Column(

                                  children: [
                                    snapshot.hasData ?  buildStateCard(state) : SizedBox(),
                                    ListView.builder(
                                      itemCount: gameplays.length,
                                      shrinkWrap: true,
                                      itemBuilder: (context, index) {
                                        return buildSectionCard(gameplays[index], null);
                                      },
                                    )
                                  ],
                                );
                              },
                            ),

                          ],
                        );
                      },

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

  Widget buildSectionCard(Gameplay section, Uint8List? preview) {
    return Card(
        child: InkWell(

          onTap: () {

          },
          child: Column(
            children: [
              preview != null
                  ? Image.memory(preview, height: 200)
                  : CircularProgressIndicator(),
              Text(section.song == null ? "Unknown" : section.song!.title),
              //Text(section.score.score.toString()),
            ],
          ),
        ));
  }
}
