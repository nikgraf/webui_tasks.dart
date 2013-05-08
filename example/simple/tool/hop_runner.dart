library hop_runner;

import 'dart:async';
import 'dart:io';
import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart';
import 'package:webui_tasks/webui_tasks.dart';

void main() {
  String entryPointPath = "web/simple.html";
  
  Task w2d = createWebui2DartTask(entryPointPath);
  addTask("w2d", w2d);
  
  Task d2d = createDartCompilerTask(["output/simple.html_bootstrap.dart"],outputType:CompilerTargetType.DART);
  addTask("d2d", d2d);
  
  Task d2js = createDart2JsTask(["output/simple.html_bootstrap.dart"], liveTypeAnalysis: true, rejectDeprecatedFeatures: true);
  addTask("d2js", d2js);
  
  Task co = createCopyOutTask(entryPointPath);
  addTask("co", co);
  
  Task fix = createFixUrlTask("output/simple.html");
  addTask("fix",fix);
  
  addChainedTask('w2d2js', ['w2d','d2js','co']);
  
  runHop();
}