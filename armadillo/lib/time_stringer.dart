// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

final DateFormat _kShortStringDateFormat = new DateFormat('h:mm', 'en_US');
final DateFormat _kLongStringDateFormat = new DateFormat('EEEE h:mm', 'en_US');

/// Creates time strings and notifies when they change.
class TimeStringer {
  final Set<VoidCallback> _listeners = new Set<VoidCallback>();
  Timer _timer;

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    if (_listeners.length == 1) {
      _scheduleTimer();
    }
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    if (_listeners.length == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  String get shortString => _kShortStringDateFormat
      .format(
        new DateTime.now().toLocal(),
      )
      .toLowerCase();

  String get longString => _kLongStringDateFormat
      .format(
        new DateTime.now().toLocal(),
      )
      .toLowerCase();

  void _scheduleTimer() {
    _timer?.cancel();
    _timer =
        new Timer(new Duration(seconds: 61 - new DateTime.now().second), () {
      _notifyListeners();
      _scheduleTimer();
    });
  }

  void _notifyListeners() {
    _listeners.toList().forEach((VoidCallback listener) => listener());
  }
}
