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