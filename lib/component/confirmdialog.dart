import 'package:flutter/material.dart';

class ConfirmDialog extends StatefulWidget {
  /// initial selection for the slider
  final String title;
  final Widget childWidget;
  final Color bgColor;
  final Color btnYesColor;
  final Color btnNoColor;

  const ConfirmDialog(
      {Key key,
      this.title,
      this.childWidget,
      this.bgColor,
      this.btnNoColor,
      this.btnYesColor})
      : super(key: key);

  @override
  _ConfirmDialogState createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog> {
  /// current selection of the slider
  bool _selectedValue;
  String _title;
  Widget _childWidget;
  Color _bgColor;
  Color _btnYesColor;
  Color _btnNoColor;

  @override
  void initState() {
    super.initState();
    _selectedValue = false;
    _title = widget.title;
    _childWidget = widget.childWidget;
    _bgColor = widget.bgColor;
    _btnNoColor = widget.btnNoColor;
    _btnYesColor = widget.btnYesColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _title,
        style: TextStyle(fontSize: 30.0),
        textAlign: TextAlign.center,
      ),
      backgroundColor: _bgColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0))),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _childWidget,
          SizedBox(
            height: 20.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: MaterialButton(
                  height: 50.0,
                  elevation: 2.0,
                  color: _btnYesColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0))),
                  onPressed: () {
                    _selectedValue = true;
                    // Use the second argument of Navigator.pop(...) to pass
                    // back a result to the page that opened the dialog
                    Navigator.pop(context, _selectedValue);
                  },
                  child: Text(
                    'YES',
                    style: TextStyle(fontSize: 20.0),
                  ),
                ),
              ),
              SizedBox(
                width: 30.0,
              ),
              Expanded(
                child: MaterialButton(
                  height: 50.0,
                  elevation: 2.0,
                  color: _btnNoColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0))),
                  onPressed: () {
                    _selectedValue = false;
                    // Use the second argument of Navigator.pop(...) to pass
                    // back a result to the page that opened the dialog
                    Navigator.pop(context, _selectedValue);
                  },
                  child: Text(
                    'NO',
                    style: TextStyle(fontSize: 20.0),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
      actions: <Widget>[],
    );
  }
}
