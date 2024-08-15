import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:imperator_desktop/core/config.dart';
import 'package:imperator_desktop/core/cv/processors.dart';
import 'package:validator_regex/validator_regex.dart';

class LivePage extends StatefulWidget {
  const LivePage();

  @override
  State<StatefulWidget> createState() => _LivePage();
}

class _LivePage extends State<LivePage> {
  FrameProcessor? processor;
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
      WidgetsBinding.instance!.addPostFrameCallback((_) async {
        await showDialog(context: context, builder: (context) {
          return AlertDialog(
            title: const Text("OBS Configuration"),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Let's set your OBS configuration. You can change this in the settings later."),
                  Text("This uses OBS's websocket feature. To configure it, go to Tools -> WebSockets Server Settings."),
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
                        Config.set("live/port", int.parse(myController[1].text));
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
        }, barrierDismissible: false);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

