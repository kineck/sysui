// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The minimum dp width a panel should have.
const double _kMinPanelWidth = 320.0;

/// The minimum dp height a panel should have.
const double _kMinPanelHeight = 320.0;

/// The number of grid lines the grid should have in either direction.
/// TODO(apwilson): This should be calculated from [size] rather than being a
/// constant.
const double _kGridLines = 1000.0;

/// Returns the maximum rows the panel grid should have given [size].
int maxRows(Size size) => math.max(
      1,
      math.min(
        (size.height / _kMinPanelHeight).floor(),
        size.height > size.width ? 3 : 2,
      ),
    );

/// Returns the maximum columns the panel grid should have given [size].
int maxColumns(Size size) => math.max(
      1,
      math.min(
        (size.width / _kMinPanelWidth).floor(),
        size.height > size.width ? 2 : 3,
      ),
    );

/// Assuming the 1.0 x 1.0 grid is mapped to a width of [width], returns the
/// minimum [0.0, 1.0] widthFactor a panel should have.
double smallestWidthFactor(double width) => _kMinPanelWidth / width;

/// Assuming the 1.0 x 1.0 grid is mapped to a height of [height], returns the
/// minimum [0.0, 1.0] heightFactor a panel should have.
double smallestHeightFactor(double height) => _kMinPanelHeight / height;

/// Rounds [value] to the nearest grid line.
double toGridValue(double value) => (value * _kGridLines).round() / _kGridLines;

/// Given an [initialSpan] being divided into [count] sections, [getSpanSpan]
/// returns the portion of [initialSpan] that should be given to the [index]th
/// section.
double getSpanSpan(double initialSpan, int index, int count) {
  double optimalSpan = toGridValue(initialSpan / count);
  double optimalDelta = toGridValue(initialSpan - optimalSpan * count);
  int optimalGridDelta = (optimalDelta * _kGridLines).round();
  return optimalSpan +
      ((index < optimalGridDelta.abs())
          ? (optimalGridDelta > 0.0 ? 1.0 / _kGridLines : -1.0 / _kGridLines)
          : 0.0);
}

/// Returns the results of [Panel.split]
typedef void PanelSplitResultCallback(Panel a, Panel b);

/// Returns the results of [Panel.absorb]
typedef void PanelAbsorbedResultCallback(Panel combined, Panel remainder);

/// A representation of a sub-area of a 1.0 x 1.0 grid with gridlines every
/// 1.0 / [_kGridLines].  [Panel]s top left is specified by [origin] and its
/// width and height by [widthFactor] and [heightFactor] respectively.
/// [origin.dx], [origin.dy], [widthFactor], and [heightFactor] all must be in
/// the range of [0.0, 1.0].
/// [origin.dx] + [widthFactor] and [origin.dy] + [heightFactor] both must be
/// in the range [0.0, 1.0].
///
/// We represent the bounds of a panel in these dimensionless [0.0, 1.0] values
/// because a given [Panel] may need to be applied more than one 'real' size.
class Panel {
  final FractionalOffset origin;
  final double heightFactor;
  final double widthFactor;

  Panel({
    FractionalOffset origin: FractionalOffset.topLeft,
    double heightFactor: 1.0,
    double widthFactor: 1.0,
  })
      : origin = new FractionalOffset(
          toGridValue(origin.dx),
          toGridValue(origin.dy),
        ),
        heightFactor = toGridValue(heightFactor),
        widthFactor = toGridValue(widthFactor) {
    assert(origin.dx >= 0.0 && origin.dx <= 1.0);
    assert(origin.dy >= 0.0 && origin.dy <= 1.0);
    assert(origin.dx + widthFactor >= 0.0 && origin.dx + widthFactor <= 1.0);
    assert(origin.dy + heightFactor >= 0.0 && origin.dx <= 1.0);
  }

  factory Panel.fromLTRB(
          double left, double top, double right, double bottom) =>
      new Panel(
        origin: new FractionalOffset(left, top),
        widthFactor: right - left,
        heightFactor: bottom - top,
      );

  /// Returns true if the panel can be split vertically without violating
  /// [smallestWidthFactor].
  bool canBeSplitVertically(double width) =>
      widthFactor / 2.0 >= smallestWidthFactor(width);

  /// Returns true if the panel can be split horizontally without violating
  /// [smallestHeightFactor].
  bool canBeSplitHorizontally(double height) =>
      heightFactor / 2.0 >= smallestHeightFactor(height);

  /// Splits the panel in half, passing the resulting two halves to
  /// [panelSplitResultCallback].
  void split(PanelSplitResultCallback panelSplitResultCallback) {
    bool tall = heightFactor > widthFactor;
    Panel a = new Panel(
      origin: origin,
      heightFactor: tall ? heightFactor / 2.0 : heightFactor,
      widthFactor: tall ? widthFactor : widthFactor / 2.0,
    );
    Panel b = new Panel(
      origin: origin +
          new FractionalOffset(
            tall ? 0.0 : widthFactor / 2.0,
            tall ? heightFactor / 2.0 : 0.0,
          ),
      heightFactor: tall ? heightFactor / 2.0 : heightFactor,
      widthFactor: tall ? widthFactor : widthFactor / 2.0,
    );
    panelSplitResultCallback(a, b);
  }

  /// Returns true if [other.origin] aligns with [origin] in an axis.
  bool isOriginAligned(Panel other) =>
      (origin.dx == other.origin.dx || origin.dy == other.origin.dy);

  /// Returns true if [isOriginAligned] returns true and [other] shares
  /// an edge with this panel.
  bool isAdjacentWithOriginAligned(Panel other) =>
      isOriginAligned(other) &&
      (origin.dx + widthFactor == other.origin.dx ||
          origin.dy + heightFactor == other.origin.dy ||
          other.origin.dx + other.widthFactor == origin.dx ||
          other.origin.dy + other.heightFactor == origin.dy);

  /// Absorbs as much of [other] as it can.  Calls [panelAbsorbedResultCallback]
  /// with its new size and the remaining unabsorbed area.
  void absorb(
      Panel other, PanelAbsorbedResultCallback panelAbsorbedResultCallback) {
    if (!isAdjacentWithOriginAligned(other)) {
      // Can't absorb anything.
      panelAbsorbedResultCallback(this, other);
      return;
    }

    if (origin.dx == other.origin.dx && other.widthFactor >= widthFactor) {
      double absorbedHeightFactor = this.heightFactor + other.heightFactor;
      double widthFactor = this.widthFactor;
      FractionalOffset absorbedOrigin = new FractionalOffset(
        origin.dx,
        math.min(origin.dy, other.origin.dy),
      );
      panelAbsorbedResultCallback(
        new Panel(
          origin: absorbedOrigin,
          widthFactor: widthFactor,
          heightFactor: absorbedHeightFactor,
        ),
        new Panel(
          origin:
              new FractionalOffset(origin.dx + widthFactor, other.origin.dy),
          widthFactor: other.widthFactor - widthFactor,
          heightFactor: other.heightFactor,
        ),
      );
    } else if (origin.dy == other.origin.dy &&
        other.heightFactor >= heightFactor) {
      double absorbedWidthFactor = this.widthFactor + other.widthFactor;
      double heightFactor = this.heightFactor;
      FractionalOffset absorbedOrigin = new FractionalOffset(
        math.min(origin.dx, other.origin.dx),
        origin.dy,
      );
      panelAbsorbedResultCallback(
        new Panel(
          origin: absorbedOrigin,
          widthFactor: absorbedWidthFactor,
          heightFactor: heightFactor,
        ),
        new Panel(
          origin:
              new FractionalOffset(other.origin.dx, origin.dy + heightFactor),
          widthFactor: other.widthFactor,
          heightFactor: other.heightFactor - heightFactor,
        ),
      );
    } else {
      // Can't absorb anything.
      panelAbsorbedResultCallback(this, other);
    }
  }

  bool _overlaps(Panel other) {
    Rect fractionalRect = new Rect.fromLTWH(
      origin.dx,
      origin.dy,
      widthFactor,
      heightFactor,
    );

    Rect otherFractionalRect = new Rect.fromLTWH(
      other.origin.dx,
      other.origin.dy,
      other.widthFactor,
      other.heightFactor,
    );

    Rect intersection = fractionalRect.intersect(otherFractionalRect);

    return (intersection.width > 0.0 && intersection.height > 0.0);
  }

  /// Returns true if [other] is above [this] [Panel].
  bool isBelow(Panel other) =>
      (other.origin.dy + other.heightFactor == origin.dy) &&
      ((other.origin.dx >= origin.dx &&
              other.origin.dx < origin.dx + widthFactor) ||
          (other.origin.dx < origin.dx &&
              other.origin.dx + other.widthFactor > origin.dx));

  /// Returns true if [other] is to the left  of [this] [Panel].
  bool isRightOf(Panel other) =>
      (other.origin.dx + other.widthFactor == origin.dx) &&
      ((other.origin.dy >= origin.dy &&
              other.origin.dy < origin.dy + heightFactor) ||
          (other.origin.dy < origin.dy &&
              other.origin.dy + other.heightFactor > origin.dy));

  /// Returns the area of the [Panel].
  double get sizeFactor => widthFactor * heightFactor;

  @override
  String toString() {
    return 'Panel(origin: $origin, widthFactor: $widthFactor, heightFactor: $heightFactor)';
  }

  static void haveFullCoverage(List<Panel> panels) {
    // First verify all locations don't overlap.
    for (int i = 0; i < panels.length; i++) {
      for (int j = i + 1; j < panels.length; j++) {
        if (panels[i]._overlaps(panels[j])) {
          print('Overlap detected between ${panels[i]} and ${panels[j]}');
          panels.forEach((Panel panel) {
            print('   $panel');
          });
          assert(false);
        }
      }
    }
    // Next sum their areas - they should equal 1.0.
    int areaSum = 0;
    panels.forEach((Panel panel) {
      areaSum +=
          (panel.widthFactor * panel.heightFactor * _kGridLines * _kGridLines)
              .round();
    });
    if (areaSum != (_kGridLines.round() * _kGridLines.round())) {
      print('Area covered was not 1.0! $areaSum');
      print('----------------------------------');
      panels.forEach((Panel panel) {
        print('$panel');
      });
      print('----------------------------------');
    }
    assert(areaSum == (_kGridLines.round() * _kGridLines.round()));
  }
}
