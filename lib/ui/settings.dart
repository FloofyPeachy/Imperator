import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:imperator_desktop/core/config.dart';
import 'package:imperator_desktop/core/util.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsPage();
}

class _SettingsPage extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: dH(context) * 1.4),
      child: Material(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: Config.settings.value.length,
          itemBuilder: (context, index) {
            var category = Config.settings.value.keys.toList()[index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category, style: TextStyle(fontSize: 20)),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: Config.settings.value[category]!.length,
                    itemBuilder: (context, index) {
                      var option = Config.settings.value[category]!.values.toList()[index];
                      return SettingsWidget(category, option);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class SettingsWidget extends StatefulWidget {
  String category;
  ConfigOption option;

  SettingsWidget(this.category, this.option, {super.key});
  @override
  State<StatefulWidget> createState() => _SettingsWidget();

}

class _SettingsWidget extends State<SettingsWidget> {

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Builder(
          builder: (context) {
            switch (widget.option.defaultValue.runtimeType) {
              case bool:
                return SwitchListTile(
                  title: Text(widget.option.name),
                  value: widget.option.value,
                  subtitle: Text(Config.getDescription("${widget.category}/${widget.option.internalName}") ?? ""),
                  onChanged: (value) {
                    setValue(value);
                  },
                );
              case int:
                return TextButton(
                  onPressed: () async {
                    var color = await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Pick a color"),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: Color(widget.option.value),
                              onColorChanged: (color) {
                                setState(() {
                                  widget.option.value = color.value;
                                });
                              },
                              showLabel: true,
                              pickerAreaHeightPercent: 0.8,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                setValue( widget.option.value);
                                Navigator.pop(context);
                              },
                              child: const Text("OK"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Row(
                    children: [
                      Text(widget.option.name),
                      Text(Config.getDescription("${widget.category}/${widget.option.internalName}") ?? ""),
                    ],
                  ),
                );
              default:
                return Text("Unknown type");
            }
          },
        ),


      ],
    );
  }


  void setValue(dynamic value) {
    widget.option.value = value;
    Config.set(widget.category + "/" + widget.option.internalName, value);

  }
}