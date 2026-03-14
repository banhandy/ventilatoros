import 'package:flutter/material.dart';
import 'package:flutterappventilator/dtmodel.dart';
import 'package:flutterappventilator/constants.dart';

class SimpleGraph extends StatefulWidget {
  final double maxY;
  final double minY;
  final double minX;
  final double maxX;
  final int totalSegmentY;
  final List<GraphXYData> dataSet;
  final Color backgroundColor;
  final Color lineColor;
  final Color segmentYColor;

  SimpleGraph(
      {this.minY = 0.0,
      this.maxY = 1.0,
      this.maxX = 1.0,
      this.minX = 0.0,
      @required this.dataSet,
      this.totalSegmentY = 5,
      this.backgroundColor = Colors.black,
      this.segmentYColor = Colors.white,
      this.lineColor = Colors.redAccent});

  @override
  _SimpleGraphState createState() => _SimpleGraphState();
}

class _SimpleGraphState extends State<SimpleGraph> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: widget.backgroundColor,
      child: ClipRect(
        child: CustomPaint(
          painter: Graphic(
              maxYData: widget.maxY * 1.2,
              minYData: widget.minY * 1.2,
              maxXData: widget.maxX * 1.2,
              minXData: widget.minX * 1.2,
              countLine: widget.totalSegmentY,
              dataSet: widget.dataSet,
              bgColor: widget.backgroundColor,
              lineColor: widget.lineColor,
              helperLineColor: widget.segmentYColor),
        ),
      ),
    );
  }
}

class Graphic extends CustomPainter {
  final double minYData;
  final double maxYData;
  final double minXData;
  final double maxXData;
  final int countLine;
  final List<GraphXYData> dataSet;

  final Color bgColor;
  final Color helperLineColor;
  final Color lineColor;

  Graphic(
      {this.minYData,
      this.maxYData,
      this.minXData,
      this.maxXData,
      this.dataSet,
      this.countLine,
      this.bgColor,
      this.helperLineColor,
      this.lineColor});

  double _maxDataY;
  double _maxDataX;
  double _maxRangeY;
  int _numberLine;
  double _drawRatioY;
  double _drawRatioX;
  double _maxRangeX;
  int _numberSeperationX;
  double _segmentSpaceX;
  double _segmentSpaceY;
  double newMinY = 0;
  double newMaxY = 0;
  double newMaxX = 0;
  double newMinX = 0;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < dataSet.length; i++) {
      if (newMaxY < dataSet[i].y) newMaxY = dataSet[i].y;
      if (newMinY > dataSet[i].y) newMinY = dataSet[i].y;
      if (newMaxX < dataSet[i].x) newMaxX = dataSet[i].x;
      if (newMinX > dataSet[i].x) newMinX = dataSet[i].x;
    }
    if (newMaxY < maxYData) newMaxY = maxYData;
    if (newMinY > minYData) newMinY = minYData;
    if (newMaxX < maxXData) newMaxX = maxXData;
    if (newMinX > minXData) newMinX = minXData;

    _maxDataY = newMaxY - newMinY;
    _maxDataX = newMaxX - newMinX;

//    _maxDataY = maxYData - minYData;
//    _maxDataX = maxXData - minXData;
    _maxRangeY = size.height - 30;
    _numberLine = countLine;
    _drawRatioY = _maxDataY / _maxRangeY;

    _maxRangeX = size.width - 30;
    _drawRatioX = _maxDataX / _maxRangeX;

    //todo cari tau dapat dari mana numberseperationx 4
    _numberSeperationX = kXSegment;
    _segmentSpaceX = _maxRangeX / _numberSeperationX;
    _segmentSpaceY = _maxRangeY / _numberLine;

    drawArea(canvas, size);
    drawData(canvas, size);
  }

  double originConvertX(double x) {
    return x + 30;
  }

  double originConvertY(double y, double height) {
    return -1 * y + (height - 30);
  }

  void drawData(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = lineColor;

    Path trace = Path();
    if (dataSet.length != 0) {
//      trace.moveTo(originConvertX((dataSet[0].x - minXData) / _drawRatioX),
//          originConvertY((dataSet[0].y - minYData) / _drawRatioY, size.height));
      trace.moveTo(originConvertX((dataSet[0].x - newMinX) / _drawRatioX),
          originConvertY((dataSet[0].y - newMinY) / _drawRatioY, size.height));
      for (int p = 1; p < dataSet.length; p++) {
//        double plotPoint = originConvertY(
//            (dataSet[p].y - minYData) / _drawRatioY, size.height);
//        double plotPointX =
//            originConvertX((dataSet[p].x - minXData) / _drawRatioX);
        double plotPoint =
            originConvertY((dataSet[p].y - newMinY) / _drawRatioY, size.height);
        double plotPointX =
            originConvertX((dataSet[p].x - newMinX) / _drawRatioX);
        trace.lineTo(plotPointX, plotPoint);
      }
    }
    canvas.drawPath(trace, paint);
  }

  void drawArea(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = helperLineColor;
    canvas.drawLine(Offset(30, 0), Offset(30, size.height - 30), paint);
    canvas.drawLine(Offset(30, size.height - 30),
        Offset(size.width, size.height - 30), paint);

    for (int i = 0; i <= countLine; i++) {
      canvas.drawLine(
          Offset(originConvertX(-5.0),
              originConvertY(i * _segmentSpaceY, size.height)),
          Offset(0.0, originConvertY(i * _segmentSpaceY, size.height)),
          paint);

      canvas.drawLine(
          Offset(originConvertX(0.0),
              originConvertY(i * _segmentSpaceY, size.height)),
          Offset(size.width, originConvertY(i * _segmentSpaceY, size.height)),
          paint);
      TextPainter text = TextPainter(
        text: TextSpan(
          text:
              ((_drawRatioY * i * _segmentSpaceY) + newMinY).toStringAsFixed(1),
        ),
        textDirection: TextDirection.ltr,
      );
      text.layout(minWidth: 0, maxWidth: size.width);
      text.paint(
        canvas,
        Offset(
          originConvertX(-15.0),
          originConvertY(i * _segmentSpaceY, size.height),
        ),
      );
    }

    for (int i = 1; i <= _numberSeperationX; i++) {
      canvas.drawLine(
          Offset(originConvertX(i * _segmentSpaceX),
              originConvertY(0.0, size.height)),
          Offset(originConvertX(i * _segmentSpaceX),
              originConvertY(0.0, size.height)),
          paint);
      TextPainter text = TextPainter(
        text: TextSpan(
          text:
              ((_drawRatioX * i * _segmentSpaceX) + newMinX).toStringAsFixed(1),
        ),
        textDirection: TextDirection.ltr,
      );
      text.layout(minWidth: 0, maxWidth: size.width);
      text.paint(
        canvas,
        Offset(
          originConvertX(i * _segmentSpaceX),
          originConvertY(0, size.height),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(Graphic oldDelegate) {
    return oldDelegate.dataSet != dataSet;
  }
}
