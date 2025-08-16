import 'dart:async';

import 'package:flutter/material.dart';

/// Enum defining the types of progress dialogs available.
enum ProgressDialogType { normal, download }

/// A customizable progress dialog widget for Flutter applications.
///
/// This class provides a way to show progress dialogs with various styling options
/// and supports both normal loading and download progress display modes.
///
/// Example usage:
/// ```dart
/// final pr = ProgressDialog(context);
/// pr.style(message: 'Loading...');
/// await pr.show();
/// // ... do some work ...
/// await pr.hide();
/// ```
class ProgressDialog {
  // Constants for default values
  static const double _defaultProgress = 0.0;
  static const double _defaultMaxProgress = 96.0;
  static const double _defaultElevation = 8.0;
  static const double _defaultBorderRadius = 8.0;
  static const double _defaultProgressWidgetSize = 64.0;
  static const String _defaultMessage = "Loading...";
  static const String _defaultAssetPath = 'assets/double_ring_loading_io.gif';

  // Default text styles
  static const TextStyle _defaultProgressTextStyle = TextStyle(
    color: Colors.black,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle _defaultMessageStyle = TextStyle(
    color: Colors.black,
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
  );

  static const EdgeInsets _defaultPadding = EdgeInsets.all(8.0);

  // Instance variables
  _DialogBody? _dialog;
  late BuildContext _context;
  late BuildContext _dismissingContext;

  // Configuration variables
  String _dialogMessage = _defaultMessage;
  double _progress = _defaultProgress;
  double _maxProgress = _defaultMaxProgress;
  Widget? _customBody;
  Widget? _widgetAboveTheDialog;
  TextAlign _textAlign = TextAlign.start;
  Alignment _progressWidgetAlignment = Alignment.centerLeft;
  TextDirection _direction = TextDirection.ltr;
  bool _isShowing = false;
  ProgressDialogType _progressDialogType = ProgressDialogType.normal;
  bool _barrierDismissible = true;
  bool _showLogs = false;
  TextStyle _progressTextStyle = _defaultProgressTextStyle;
  TextStyle _messageStyle = _defaultMessageStyle;
  double _dialogElevation = _defaultElevation;
  double _borderRadius = _defaultBorderRadius;
  Color _backgroundColor = Colors.white;
  Curve _insetAnimCurve = Curves.easeInOut;
  EdgeInsets _dialogPadding = _defaultPadding;
  late Widget _progressWidget;

  final GlobalKey<_DialogBodyState> _dialogBodyKey =
      GlobalKey<_DialogBodyState>();

  /// Creates a new ProgressDialog instance.
  ///
  /// [context] - The BuildContext where the dialog will be shown
  /// [type] - The type of progress dialog (normal or download)
  /// [isDismissible] - Whether the dialog can be dismissed by tapping outside
  /// [showLogs] - Whether to show debug logs
  /// [textDirection] - The text direction for the dialog content
  /// [customBody] - A custom widget to use as the dialog body
  ProgressDialog(
    BuildContext context, {
    ProgressDialogType? type,
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

    // Initialize the default progress widget
    _progressWidget = Image.asset(
      _defaultAssetPath,
      package: 'progress_dialog_null_safe',
    );
  }

  /// Configures the styling and appearance of the progress dialog.
  ///
  /// This method allows you to customize various aspects of the dialog's appearance.
  /// All parameters are optional and will use existing values if not provided.
  ///
  /// Note: This method has no effect if the dialog is already showing.
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
    _progressWidget = progressWidget ?? child ?? _progressWidget;
    _backgroundColor = backgroundColor ?? _backgroundColor;
    _messageStyle = messageTextStyle ?? _messageStyle;
    _progressTextStyle = progressTextStyle ?? _progressTextStyle;
    _dialogElevation = elevation ?? _dialogElevation;
    _borderRadius = borderRadius ?? _borderRadius;
    _insetAnimCurve = insetAnimCurve ?? _insetAnimCurve;
    _textAlign = textAlign ?? _textAlign;
    _dialogPadding = padding ?? _dialogPadding;
    _progressWidgetAlignment =
        progressWidgetAlignment ?? _progressWidgetAlignment;
  }

  /// Updates the content of the progress dialog while it's showing.
  ///
  /// This method allows you to dynamically update the dialog's content
  /// without hiding and showing it again.
  ///
  /// All parameters are optional and will use existing values if not provided.
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

    if (_isShowing) {
      _dialog?.update();
    }
  }

  /// Returns whether the progress dialog is currently showing.
  bool isShowing() => _isShowing;

  /// Hides the progress dialog.
  ///
  /// Returns a Future<bool> that completes with true if the dialog was
  /// successfully hidden, false otherwise.
  ///
  /// Throws [ProgressDialogException] if the dialog is already dismissed.
  Future<bool> hide() async {
    try {
      if (!_isShowing) {
        throw ProgressDialogException(
          ProgressDialogExceptionType.alreadyDismissed,
        );
      }

      scheduleMicrotask(() {
        Navigator.of(
          _dismissingContext,
          rootNavigator: true,
        ).pop();
        _isShowing = false;
      });

      if (_showLogs) debugPrint('ProgressDialog dismissed');
      return Future.value(!_isShowing);
    } on ProgressDialogException catch (err) {
      debugPrint(err.type.message);
      debugPrint(err.toString());
      return Future.value(false);
    } catch (err) {
      _isShowing = false;
      debugPrint('Seems there is an issue hiding dialog');
      debugPrint(err.toString());
      return Future.value(false);
    }
  }

  /// Shows the progress dialog.
  ///
  /// Returns a Future<bool> that completes with true if the dialog was
  /// successfully shown, false otherwise.
  ///
  /// Throws [ProgressDialogException] if the dialog is already shown.
  Future<bool> show() async {
    try {
      // If the dialog is already shown, do nothing
      if (_isShowing) {
        throw ProgressDialogException(ProgressDialogExceptionType.alreadyShown);
      }

      // Show the dialog
      _dialog = _DialogBody(key: _dialogBodyKey, progressDialog: this);
      scheduleMicrotask(() {
        showDialog<dynamic>(
          context: _context,
          barrierDismissible: _barrierDismissible,
          builder: (BuildContext buildContext) {
            _dismissingContext = buildContext;
            return PopScope(
              canPop: _barrierDismissible,
              child: Dialog(
                backgroundColor: _backgroundColor,
                insetAnimationCurve: _insetAnimCurve,
                insetAnimationDuration: const Duration(milliseconds: 100),
                elevation: _dialogElevation,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(_borderRadius),
                  ),
                ),
                child: Builder(builder: (_) => _dialog!),
              ),
            );
          },
        );
        _isShowing = true;
      });

      if (_showLogs) debugPrint('ProgressDialog shown');
      return Future.value(_isShowing);
    } on ProgressDialogException catch (err) {
      debugPrint(err.type.message);
      debugPrint(err.toString());
      return Future.value(false);
    } catch (err) {
      _isShowing = false;
      debugPrint('Exception while showing the dialog');
      debugPrint(err.toString());
      return Future.value(false);
    }
  }
}

/// Internal widget class for rendering the dialog body.
///
/// This class is used internally by [ProgressDialog] and should not be
/// instantiated directly.
class _DialogBody extends StatefulWidget {
  final ProgressDialog progressDialog;

  const _DialogBody({
    super.key,
    required this.progressDialog,
  });

  /// Updates the dialog content by calling setState on the current state.
  void update() =>
      (key as GlobalKey<_DialogBodyState>?)?.currentState?.update();

  @override
  State<StatefulWidget> createState() => _DialogBodyState();
}

/// State class for [_DialogBody].
class _DialogBodyState extends State<_DialogBody> {
  /// Updates the dialog by calling setState.
  void update() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.progressDialog._isShowing = false;
    if (widget.progressDialog._showLogs) {
      debugPrint('ProgressDialog dismissed by back button');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pd = widget.progressDialog;

    final loader = Align(
      alignment: pd._progressWidgetAlignment,
      child: SizedBox(
        width: ProgressDialog._defaultProgressWidgetSize,
        height: ProgressDialog._defaultProgressWidgetSize,
        child: pd._progressWidget,
      ),
    );

    final text = Builder(
      builder: (BuildContext buildContext) {
        if (pd._progressDialogType == ProgressDialogType.normal) {
          return Text(
            pd._dialogMessage,
            textAlign: pd._textAlign,
            style: pd._messageStyle,
            textDirection: pd._direction,
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 8.0),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        pd._dialogMessage,
                        style: pd._messageStyle,
                        textDirection: pd._direction,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    "${pd._progress}/${pd._maxProgress}",
                    style: pd._progressTextStyle,
                    textDirection: pd._direction,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );

    if (pd._customBody != null) {
      return Directionality(
        textDirection: pd._direction,
        child: pd._customBody!,
      );
    } else {
      return Directionality(
        textDirection: pd._direction,
        child: Container(
          padding: pd._dialogPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (pd._widgetAboveTheDialog != null) pd._widgetAboveTheDialog!,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(width: 8.0),
                  loader,
                  const SizedBox(width: 8.0),
                  Expanded(child: text),
                  const SizedBox(width: 8.0)
                ],
              ),
            ],
          ),
        ),
      );
    }
  }
}

/// Enum defining the types of exceptions that can occur with ProgressDialog.
enum ProgressDialogExceptionType {
  alreadyShown,
  alreadyDismissed,
}

/// Extension providing user-friendly messages for [ProgressDialogExceptionType].
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

/// Custom exception class for ProgressDialog-specific errors.
///
/// This exception is thrown when operations are performed on the dialog
/// in inappropriate states (e.g., trying to show an already shown dialog).
class ProgressDialogException implements Exception {
  /// The type of exception that occurred.
  final ProgressDialogExceptionType type;

  /// Optional custom message for the exception.
  final String? message;

  /// Creates a new ProgressDialogException.
  ///
  /// [type] - The type of exception
  /// [message] - Optional custom message
  ProgressDialogException(this.type, [this.message]);

  @override
  String toString() {
    if (message == null) return "DialogException";
    return "DialogException: $message";
  }
}
