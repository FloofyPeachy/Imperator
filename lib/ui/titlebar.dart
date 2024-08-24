import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:imperator_desktop/core/config.dart';
import 'package:imperator_desktop/core/util.dart';
import 'package:imperator_desktop/ui/settings.dart';
import 'package:window_manager/window_manager.dart';

class TitleBar extends StatefulWidget {
  GlobalKey<NavigatorState> navigator;

  TitleBar(this.navigator, {super.key});
  @override
  State<StatefulWidget> createState() => _TitleBar();

}

class _TitleBar extends State<TitleBar> {
  bool settingsOpen = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      //1D1D1D
      color: Config.get("appearance/dark_mode") ? Color(0xFF1D1D1D) : Color(0xFFE0E0E0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (TapDownDetails details) {
          windowManager.startDragging();
        },
        onSecondaryLongPressDown: (LongPressDownDetails details) {
          windowManager.popUpWindowMenu();
        },
        child: Row(
          children: [
            widget.navigator.currentState != null && widget.navigator.currentState!.canPop() ? MaterialButton(
              minWidth: 0,
              onPressed: () {
                widget.navigator.currentState!.pop();
              },
              child: const Icon(Icons.arrow_back, size: 24),

            ) : SizedBox(),
            MaterialButton(
              onPressed: () {
                if (settingsOpen) {
                  Navigator.of(widget.navigator.currentState!.overlay!.context).pop();
                  settingsOpen = false;
                  return;
                }
                showGeneralDialog(
                  barrierLabel: "Label",
                  barrierDismissible: true,
                  barrierColor: Colors.black.withOpacity(0.5),
                  transitionDuration: Duration(milliseconds: 250),

                  context:  widget.navigator.currentState!.overlay!.context,
                  pageBuilder: (context, anim1, anim2) {
                    return SettingsPage();
                  },
                  transitionBuilder: (context, anim1, anim2, child) {
                    return SlideTransition(
                      position: anim1.drive(Tween(begin: Offset(-1, 0), end: Offset(0, 0)).chain(CurveTween(curve: Curves.easeInOut))),
                      child: child,
                    );
                  },


                ).then((value) {
                  settingsOpen = false;

                });
                settingsOpen = true;
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset('assets/images/logo.svg', height: 20),
              ),
            ),
            const Spacer(),
            MaterialButton(
              minWidth: 0,
              onPressed: () {
                // Minimize the window
                windowManager.minimize();
              },
              child: const Icon(Icons.horizontal_rule, size: 16),
            ),
            MaterialButton(
              minWidth: 0,
              onPressed: () async {
                // Minimize the window
                await windowManager.isMaximized() ? windowManager.unmaximize() : windowManager.maximize();
              },
              child: const Icon(Icons.check_box_outline_blank_rounded, size: 16),
            ),
            MaterialButton(
              minWidth: 0,
              onPressed: () {
                // Minimize the window]
                windowManager.close();
              },
              child: const Icon(Icons.close, size: 16),
            ),

          ],
        ),
      ),
    );
  }
}