A Webui task library based on Hop.
==================================

# What is Webui?

Webui allows you to create web applications like you would legos, piecing the framework from reusable components.
See [article](http://www.dartlang.org/articles/web-ui/) for an introduction.

# What is Hop?

Hop is a framework that simplifies and automates console tasks in Dart.  See [Hop Pub package](http://pub.dartlang.org/packages/hop) for more information.  Also see [article](https://github.com/kevmoo/bot.dart/wiki/Using-Hop%2C-Part-1%3A-Building-and-Running-Your-First-Hop-Task-Application) for a quick tutorial.

# How will this library help me?

This library will allow you to:
* Compile webui components to Javascript in one console step as well as minidart compilation (dart to dart).
* Fix the relative Urls in the output Webui entry point Html file.
* Copy static assets such as Javascript linked from the entry point Html file into the target output directory.

_Dart Documentation coming soon._

# How do I get started?

This library isn't yet published on [pub](http://http://pub.dartlang.org/).  Meanwhile, you can add the following dependency:

```yaml
dependencies:
  webui_tasks:
    git: https://github.com/damondouglas/webui_tasks.dart
```

# Example

```dart
library hop_runner;

import 'dart:async';
import 'dart:io';
import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart';
import 'package:webui_tasks/webui_tasks.dart';

void main() {
  String entryPointPath = "web/simple.html";
  
  // Copy out static linked assets such as packages/browser/dart.js
  Task co = createCopyOutTask(entryPointPath);
  addTask("co", co);
  
  // Fix Urls in entrypoint to point to static assets and appropriate main Javascript file.
  Task fixjs = createFixUrlTask("output/simple.html", outputType:WebuiTargetType.JS);
  addTask("fixjs",fixjs);
  
  // Call DWC and dart2js compilers.
  ChainedTask w2d2js = createWebui2JsTask(entryPointPath);
  addTask("w2d2js", w2d2js);
  
  // Run all three tasks at once to deploy Javascript from webui.
  addChainedTask('deployjs', ['w2d2js','co','fixjs']);
  
  // Fix Urls in entrypoint to point to static assets and appropriate minified main Dart script file.
  Task fixmd = createFixUrlTask("output/simple.html", outputType:WebuiTargetType.MINIDART);
  addTask("fixmd", fixmd);
  
  ChainedTask w2d2d = createWebui2MiniDartTask(entryPointPath);
  addTask("w2d2d", w2d2d);
  
  // Run all three tasks at once to deploy Minidart from webui.
  addChainedTask('deploymd', ['w2d2d','co','fixmd']);
  
  runHop();
}
```
### Deploy project as Javascript
1. Run in webui project root as `dart tool/hop_runner.dart deployjs`
2. Open `output/simple.html` in any modern browser. See [hosted example](https://googledrive.com/host/0B315YrNkj-ZxeEluMlRnX0xOYTQ/simple.html).

### Deploy project as mini dart
1. Run in webui project root as `dart tool/hop_runner.dart deploymd`
2. Open `output/simple.html` in Chromium.

From [example](https://github.com/damondouglas/webui_tasks.dart/blob/master/example/simple/tool/hop_runner.dart) in [sample webui project](https://github.com/damondouglas/webui_tasks.dart/tree/master/example/simple)

## Authors
 * [Damon Douglas](https://github.com/damondouglas) ([+Damon Douglas](https://plus.google.com/u/0/108940381045821372455/))
 * _You? File bugs. Fork and Fix bugs. Let's build this community._

## Acknowledgements
* [Kevin Moore](https://github.com/kevmoo) for his work on the [Hop](https://github.com/kevmoo/hop.dart) and [Webui Widget](https://github.com/kevmoo/widget.dart) libraries, from which much of this code and methodology derives.
* [Seth Ladd](https://github.com/sethladd) for [his original idea](https://groups.google.com/a/dartlang.org/d/msg/web-ui/Xvk3BU8NnxI/S13aR6zh3wYJ) that inspired the project.
