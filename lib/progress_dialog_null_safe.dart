import 'package:flutter/material.dart';

enum ProgressDialogType { normal, download, }

String _dialogMessage = "Loading...";
double _progress = 0.0, _maxProgress = 96.0;

Widget? _customBody;
Widget? _widgetAboveTheDialog;

TextAlign _textAlign = TextAlign.start;
Alignment _progressWidgetAlignment = Alignment.centerLeft;

TextDirection _direction = TextDirection.ltr;

bool _isShowing = false;
late BuildContext _context, _dismissingContext;
ProgressDialogType? _progressDialogType;
bool _barrierDismissible = true, _showLogs = false;

TextStyle _progressTextStyle = const TextStyle(
  color: Colors.black, fontSize: 12.0, fontWeight: FontWeight.w400,
);
TextStyle _messageStyle = const TextStyle(
  color: Colors.black, fontSize: 18.0, fontWeight: FontWeight.w600,
);

double _dialogElevation = 8.0, _borderRadius = 8.0;
Color _backgroundColor = Colors.white;
Curve _insetAnimCurve = Curves.easeInOut;
EdgeInsets _dialogPadding = const EdgeInsets.all(8.0,);

String assetPath = 'assets/double_ring_loading_io.gif';
Widget _progressWidget = Image.asset(assetPath, package: 'progress_dialog_null_safe',);

final GlobalKey<_DialogBodyState> dialogBodyKey = GlobalKey<_DialogBodyState>();
class ProgressDialog {
  _DialogBody? _dialog;

  ProgressDialog(
    BuildContext context,
    {ProgressDialogType? type,
    bool? isDismissible,
    bool? showLogs,
    TextDirection? textDirection,
    Widget? customBody,
  }) {
    _context = context;
    _progressDialogType = type ?? ProgressDialogType.normal;
    _barrierDismissible = isDismissible ?? true;
    _showLogs = showLogs ?? false;
    _direction = textDirection ?? TextDirection.ltr;
    _customBody = customBody;
  }

  void style({
    Widget? child,
    Widget? widgetAboveTheDialog,
    double? progress,
    double? maxProgress,
    String? message,
    Widget? progressWidget,
    Color? backgroundColor,
    TextStyle? progressTextStyle,
    TextStyle? messageTextStyle,
    double? elevation,
    TextAlign? textAlign,
    double? borderRadius,
    Curve? insetAnimCurve,
    EdgeInsets? padding,
    Alignment? progressWidgetAlignment,
  }) {
    if (_isShowing) return;
    if (_progressDialogType == ProgressDialogType.download) {
      _progress = progress ?? _progress;
    }
    _widgetAboveTheDialog = widgetAboveTheDialog;
    _dialogMessage = message ?? _dialogMessage;
    _maxProgress = maxProgress ?? _maxProgress;
    _progressWidget = progressWidget ?? _progressWidget;
    _backgroundColor = backgroundColor ?? _backgroundColor;
    _messageStyle = messageTextStyle ?? _messageStyle;
    _progressTextStyle = progressTextStyle ?? _progressTextStyle;
    _dialogElevation = elevation ?? _dialogElevation;
    _borderRadius = borderRadius ?? _borderRadius;
    _insetAnimCurve = insetAnimCurve ?? _insetAnimCurve;
    _textAlign = textAlign ?? _textAlign;
    _progressWidget = child ?? _progressWidget;
    _dialogPadding = padding ?? _dialogPadding;
    _progressWidgetAlignment = progressWidgetAlignment ?? _progressWidgetAlignment;
  }

  void update({
    double? progress,
    double? maxProgress,
    String? message,
    Widget? progressWidget,
    TextStyle? progressTextStyle,
    TextStyle? messageTextStyle,
  }) {
    if (_progressDialogType == ProgressDialogType.download) {
      _progress = progress ?? _progress;
    }
    _dialogMessage = message ?? _dialogMessage;
    _maxProgress = maxProgress ?? _maxProgress;
    _progressWidget = progressWidget ?? _progressWidget;
    _messageStyle = messageTextStyle ?? _messageStyle;
    _progressTextStyle = progressTextStyle ?? _progressTextStyle;

    if(!_isShowing) {
      return;
    } else {
      _dialog!.update();
    }
  }

  bool isShowing() => _isShowing;

  Future<bool> hide() async{
    try {
      if (!_isShowing) throw ProgressDialogException(ProgressDialogExceptionType.alreadyDismissed,);

      await Future.sync(() => Navigator.of(_dismissingContext, rootNavigator: true,).pop(),).then(
        (_,) => (_showLogs) ? debugPrint('ProgressDialog dismissed') : null,
      );

      _isShowing = false;
      return Future.value(_isShowing,);
    } on ProgressDialogException catch (err) {
      debugPrint(err.type.message,);
      debugPrint(err.toString(),);
      return Future.value(false,);
    } catch (err) {
      _isShowing = false;
      debugPrint('Seems there is an issue hiding dialog');
      debugPrint(err.toString(),);
      return Future.value(false,);
    }
  }

  Future<bool> show() async{
    try {
      /// If the dialog is already shown, do nothing
      if (_isShowing) throw ProgressDialogException(ProgressDialogExceptionType.alreadyShown,);

      ///show the dialog
      _dialog = _DialogBody(key: dialogBodyKey,);
      Future.sync(
        () => showDialog<dynamic>(
          context: _context,
          barrierDismissible: _barrierDismissible,
          builder: (BuildContext buildContext,) {
            _dismissingContext = buildContext;
            return WillPopScope(
              onWillPop: () => Future.value(_barrierDismissible,),
              child: Dialog(
                backgroundColor: _backgroundColor,
                insetAnimationCurve: _insetAnimCurve,
                insetAnimationDuration: const Duration(milliseconds: 100,),
                elevation: _dialogElevation,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(_borderRadius,),),),
                child: Builder(builder: (_,) => _dialog!,),
              ),
            );
          },
        ),
      );

      ///Delaying the function for 250 milliseconds
      await Future.delayed(
        const Duration(milliseconds: 250,),
        () => (_showLogs) ? debugPrint('ProgressDialog shown') : null,
      );

      _isShowing = true;
      return Future.value(_isShowing,);
    } on ProgressDialogException catch (err) {
      debugPrint(err.type.message,);
      debugPrint(err.toString(),);
      return Future.value(false,);
    } catch (err) {
      _isShowing = false;
      debugPrint('Exception while showing the dialog',);
      debugPrint(err.toString(),);
      return Future.value(false,);
    }
  }
}

class _DialogBody extends StatefulWidget {
  const _DialogBody({Key? key,}) : super(key: key,);

  void update() => dialogBodyKey.currentState!.update();

  @override State<StatefulWidget> createState() => _DialogBodyState();
}

class _DialogBodyState extends State<_DialogBody> {
  update() {
    setState(() {});
  }

  @override void dispose() {
    _isShowing = false;
    if (_showLogs) debugPrint('ProgressDialog dismissed by back button');
    super.dispose();
  }

  @override Widget build(BuildContext context,) {
    final loader = Align(
      alignment: _progressWidgetAlignment,
      child: SizedBox(
        width: 64.0,
        height: 64.0,
        child: _progressWidget,
      ),
    );
    final text = Builder(
      builder: (BuildContext buildContext,) {
        if(_progressDialogType == ProgressDialogType.normal) {
          return Text(
            _dialogMessage,
            textAlign: _textAlign,
            style: _messageStyle,
            textDirection: _direction,
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(8.0,),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 8.0,),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _dialogMessage,
                        style: _messageStyle,
                        textDirection: _direction,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0,),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    "$_progress/$_maxProgress",
                    style: _progressTextStyle,
                    textDirection: _direction,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );

    if(_customBody != null) {
      return Directionality(
        textDirection: _direction,
        child: _customBody!,
      );
    } else {
      return Directionality(
        textDirection: _direction,
        child: Container(
          padding: _dialogPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (_widgetAboveTheDialog != null) _widgetAboveTheDialog!,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(width: 8.0,),
                  loader,
                  const SizedBox(width: 8.0,),
                  Expanded(child: text,),
                  const SizedBox(width: 8.0,)
                ],
              ),
            ],
          ),
        ),
      );
    }
  }
}

enum ProgressDialogExceptionType { alreadyShown, alreadyDismissed,}
extension ProgressDialogExceptionTypeExtension on ProgressDialogExceptionType {
  String get message {
    switch (this) {
      case ProgressDialogExceptionType.alreadyShown:
      return "ProgressDialog already shown";
      case ProgressDialogExceptionType.alreadyDismissed:
      return "ProgressDialog already dismissed";
    }
  }
}
class ProgressDialogException implements Exception {
  ProgressDialogExceptionType type;
  String? message;
  ProgressDialogException(this.type, [this.message,]);
  @override String toString() {
    if (message == null) return "DialogException";
    return "DialogException: $message";
  }
}
