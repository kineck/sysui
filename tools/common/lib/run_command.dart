// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

/// Runs the shell command [command] and returns its standard output.
Future<String> runCommand(String command, {String workingDirectory}) async {
  final args = command.split(' ');
  final result = await Process.run(args[0], args.sublist(1),
      workingDirectory: workingDirectory);
  if (result.exitCode != 0) {
    print(
        'Error running $command from ${workingDirectory ?? Directory.current}');
    print('stdout');
    print('------------------------');
    print(result.stdout.trim());
    print('------------------------');
    print('stderr');
    print('------------------------');
    print(result.stderr);
    print('------------------------');
    exit(result.exitCode);
    return null;
  }
  return result.stdout.trim();
}
