import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GraphDBWithPointer extends StatefulWidget {
  final int index;
  final double maxY;
  final double minY;
  final int totalSegmentY;
  final List dataSet;
  final Color backgroundColor;
  final Color lineColor;
  final Color segmentYColor;

  GraphDBWithPointer(
      {@required this.index,
      this.minY = 1.0,
      this.maxY = 0.0,
      @required this.dataSet,
      this.totalSegmentY = 5,
      this.backgroundColor = Colors.black,
      this.segmentYColor = Colors.white,
      this.lineColor = Colors.redAccent});

  @override
  _GraphDBWithPointerState createState() => _GraphDBWithPointerState();
}

class _GraphDBWithPointerState extends State<GraphDBWithPointer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: widget.backgroundColor,
      child: GestureDetector(
        child: ClipRect(
          child: CustomPaint(
            painter: Graphic(
                index: widget.index,
                maxData: widget.maxY * 1.2,
                minData: widget.minY * 1.2,
                countLine: widget.totalSegmentY,
                dataSet: widget.dataSet,
                bgColor: widget.backgroundColor,
                lineColor: widget.lineColor,
                helperLineColor: widget.segmentYColor),
          ),
        ),
      ),
    );
  }
}

class Graphic extends CustomPainter {
  final double minData;
  final double maxData;
  final int countLine;
  final List dataSet;
  final int index;
  final Color bgColor;
  final Color helperLineColor;
  final Color lineColor;

  Graphic(
      {this.index,
      this.minData,
      this.maxData,
      this.dataSet,
      this.countLine,
      this.bgColor,
      this.helperLineColor,
      this.lineColor});

  double _maxDataY;
  double _maxRangeY;
  int _numberLine;
  double _drawRatioY;
  double _maxRangeX;
  double _numberSeperationX;
  double _segmentSpaceX;
  double _segmentSpaceY;

  ///variable for dynamic area
  double newMax = 0;
  double newMin = 0;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < dataSet.length; i++) {
      if (newMax < dataSet[i]) newMax = dataSet[i];
      if (newMin > dataSet[i]) newMin = dataSet[i];
    }
    if (newMax < maxData) newMax = maxData;
    if (newMin > minData) newMin = minData;
    //_maxDataY = maxData - minData;
    ///dynamic area
    _maxDataY = newMax - newMin;
    _maxRangeY = size.height - 30;
    _numberLine = countLine;
    _drawRatioY = _maxDataY / _maxRangeY;
    _maxRangeX = size.width - 30;
    _numberSeperationX = dataSet.length.toDouble();
    _segmentSpaceX = _maxRangeX / _numberSeperationX;
    _segmentSpaceY = _maxRangeY / _numberLine;

    drawArea(canvas, size);

    drawPosition2(canvas, size);
    drawData(canvas, size);
    drawBubbleText(canvas, size);
    //drawPosition(canvas, size);
  }

  double originConvertX(double x) {
    return x + 30;
  }

  double originConvertY(double y, double height) {
    return -1 * y + (height - 30);
  }

  void drawBubbleText(Canvas canvas, Size size) {
    final paintShadow = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black12;

    int factor = 0;
    if (dataSet.length == 150) factor = 1;
    if (dataSet.length == 300) factor = 2;
    if (dataSet.length == 600) factor = 4;

    Path path = Path();
    Offset center = Offset(
      originConvertX(
          (index > 60 * factor ? index - (10 * factor) : index + (9 * factor)) *
              _segmentSpaceX),
      originConvertY((dataSet[index] - newMin) / _drawRatioY, size.height),
    );
    path.moveTo(center.dx - 100 / 2 + 2, center.dy - 2 + 40 / 1.8);
    path.lineTo(center.dx + 100 / 2 + 2, center.dy - 2 + 40 / 1.8);
    path.lineTo(center.dx + 100 / 2 + 2, center.dy - 2 - 40 / 3);
    //path.close();
    // canvas.drawShadow(path, Colors.black, 20.0, false);
    canvas.drawPath(path, paintShadow);

    final paintBubble = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.redAccent;

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            _fromCenter(center: center, width: 100.0, height: 40.0),
            Radius.circular(5.0)),
        paintBubble);

    if (index <= dataSet.length - 1) {
      TextPainter text = TextPainter(
        textAlign: TextAlign.center,
        text: TextSpan(
            text: (dataSet[index]).toStringAsFixed(0),
            style: TextStyle(color: Colors.white, fontSize: 20.0)),
        textDirection: TextDirection.ltr,
      );
      text.layout();

      text.paint(
        canvas,
        Offset(
          center.dx - text.width / 2,
          center.dy - 2 - 40 / 3.5,
        ),
      );
    }
  }

  void drawPosition2(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * _segmentSpaceX
      ..color = Colors.red;
    Path trace = Path();
    trace.moveTo(originConvertX((index) * _segmentSpaceX), 0);

    double plotPoint = size.height - 30;
    trace.lineTo(originConvertX((index) * _segmentSpaceX), plotPoint);
    canvas.drawPath(trace, paint);

    final paintCircle = Paint()
      ..style = PaintingStyle.fill
      ..color = lineColor;

    canvas.drawCircle(
        Offset(
            originConvertX((index) * _segmentSpaceX),
            originConvertY(
                (dataSet[index] - newMin) / _drawRatioY, size.height)),
        5.0,
        paintCircle);
  }

  Rect _fromCenter({Offset center, double width, double height}) =>
      Rect.fromLTRB(
        center.dx - width / 2,
        center.dy - height / 2,
        center.dx + width / 2,
        center.dy + height / 2,
      );

  void drawPosition(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = bgColor;
    if (index < 2)
      canvas.drawRect(
          Rect.fromLTRB(originConvertX((index) * _segmentSpaceX), 0,
              originConvertX((index) * _segmentSpaceX), size.height - 30),
          paint);
    else
      canvas.drawRect(
          Rect.fromLTRB(originConvertX((index - 2) * _segmentSpaceX), 0,
              originConvertX((index) * _segmentSpaceX), size.height - 30),
          paint);
  }

  void drawData(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = lineColor;

    Path trace = Path();
    //trace.moveTo(originConvertX((0) * _segmentSpaceX),
    //    originConvertY((dataSet[0] - minData) / _drawRatioY, size.height));
    trace.moveTo(originConvertX((0) * _segmentSpaceX),
        originConvertY((dataSet[0] - newMin) / _drawRatioY, size.height));

    for (int p = 1; p < dataSet.length; p++) {
//      double plotPoint =
//          originConvertY((dataSet[p] - minData) / _drawRatioY, size.height);

      double plotPoint =
          originConvertY((dataSet[p] - newMin) / _drawRatioY, size.height);

      trace.lineTo(originConvertX(p.toDouble() * _segmentSpaceX), plotPoint);
    }

    canvas.drawPath(trace, paint);
  }

  void drawArea(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = helperLineColor;
    final paintAccent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white38;
    canvas.drawLine(Offset(30, 0), Offset(30, size.height - 30), paint);
    canvas.drawLine(Offset(30, size.height - 30),
        Offset(size.width, size.height - 30), paint);
    //todo buat variable untuk 10, dan 200ms
    for (int i = 1; i < dataSet.length; i++) {
      if (i % 30 == 0) {
        canvas.drawLine(
            Offset(originConvertX(i * _segmentSpaceX),
                originConvertY(0.0, size.height)),
            Offset(originConvertX(i * _segmentSpaceX),
                originConvertY(0.0, size.height)),
            paintAccent);
        TextPainter text = TextPainter(
          text: TextSpan(
            text: ((i * 100 / 1000)).toStringAsFixed(0),
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

    for (int i = 0; i <= countLine; i++) {
      canvas.drawLine(
          Offset(originConvertX(-5.0),
              originConvertY(i * _segmentSpaceY, size.height)),
          Offset(0.0, originConvertY(i * _segmentSpaceY, size.height)),
          paintAccent);

      canvas.drawLine(
          Offset(originConvertX(0.0),
              originConvertY(i * _segmentSpaceY, size.height)),
          Offset(size.width, originConvertY(i * _segmentSpaceY, size.height)),
          paintAccent);
      TextPainter text = TextPainter(
        text: TextSpan(
          text:
              ((_drawRatioY * i * _segmentSpaceY) + newMin).toStringAsFixed(1),
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
  }

  @override
  bool shouldRepaint(Graphic oldDelegate) {
    return oldDelegate.index != index;
  }
}
