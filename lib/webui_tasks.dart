library webui_tasks;

import 'dart:io';
import 'dart:async';
import 'package:bot/bot.dart';
import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart';
import 'package:html5lib/parser.dart';
import 'package:html5lib/dom.dart';

// Adapted from CompilerTargetType courtesy of:  https://github.com/kevmoo/hop.dart/blob/master/lib/src/hop_tasks/dart2js.dart
class WebuiTargetType {
  final String _value;
  const WebuiTargetType._internal(this._value);
  String toString() => 'CompilerTargetType.$_value';
  String get fileExt => _value;
  static const JS = const WebuiTargetType._internal('js');
  static const DART = const WebuiTargetType._internal('dart');
  static const MINIDART = const WebuiTargetType._internal('minidart');
}

Task createWebui2DartTask(String entryPoint, {String outputPath:"output", bool rewriteUrls:false, WebuiTargetType outputType:WebuiTargetType.DART}) {
  requireArgument(outputType == WebuiTargetType.MINIDART || outputType == WebuiTargetType.DART, 'outputType');
  
  final entryPointPath = new Path(entryPoint);
  final entryPointFile = new File.fromPath(entryPointPath);
  final entryPointFileName = entryPointPath.filename;
  final packageDir = new Directory('packages');
  
  assert(packageDir.existsSync());
  assert(entryPointFile.existsSync() && entryPoint.endsWith(".html"));
  
  return new Task.async((TaskContext context){
    return _dwc(context, outputPath, entryPoint, rewriteUrls).whenComplete((){
      context.info("Compiled Webui at: $outputPath");
    });
  });
}

Task createCopyOutTask(String entryPoint, {String outputPath:"output"}) {
  final entryPointPath = new Path(entryPoint);
  final entryPointFile = new File.fromPath(entryPointPath);
  final entryPointFileName = entryPointPath.filename;
  
  return new Task.async((TaskContext context){
    return _copy_out(context, outputPath, entryPointPath.directoryPath, entryPointFileName).whenComplete((){
      context.info("Copied Out Complete.");
    });
  });
}

Task createFixUrlTask(String entryPoint, {String outputPath:"output", WebuiTargetType outputType:WebuiTargetType.DART}) {
  
}

Future<bool> _dwc(TaskContext ctx, String output, String entryPoint, bool rewriteUrls){
  final packageDir = new Directory('packages');
  assert(packageDir.existsSync());
  
  final rewriteUrlOpt = rewriteUrls ? "--rewrite-urls" : "--no-rewrite-urls";
  
  final args = ["--package-root=${packageDir.path}/",
                "packages/web_ui/dwc.dart",
                "--out",
                "$output/",
                rewriteUrlOpt,
                entryPoint
                ];
  
  ctx.info("args: ${args.toString()}");
  return Process.start("dart", args)
      .then((process) {
        return pipeProcess(process,
            stdOutWriter: ctx.info,
            stdErrWriter: ctx.severe);
      }).then((int exitCode){
        return exitCode==1;
      });
}

Future<bool> _copy_out(TaskContext ctx, String output, String sourceDir, String entryPointFileName) {
  
  Completer completer = new Completer();
  
  var entryPoint = new File("$sourceDir/$entryPointFileName");
  var outputPath = new Path(output);
  
  assert(entryPoint.existsSync());
  
  var document = parse(entryPoint.readAsStringSync());
  var urlMap = {};
  
  document
  .queryAll("script")
  .forEach((element){
    String src = element.attributes["src"];
    
    if(!src.contains(".dart")){
        var assetPath = src.startsWith("packages/") ? new Path(src) : new Path("$sourceDir/$src");
        var assetFile = new File.fromPath(assetPath);
        var asset = assetFile.readAsStringSync();
        var copyFile = new File.fromPath(outputPath.append(assetPath.filename));
        copyFile.writeAsStringSync(asset);
        urlMap[src] = assetPath.filename;
    } 
  });
  
  entryPoint = new File("$output/$entryPointFileName");
  document = parse(entryPoint.readAsStringSync());
  
  document
  .queryAll("script")
  .forEach((element){
    String src = element.attributes["src"];
    
    if(!src.contains(".dart")) {
      element.attributes["src"] = urlMap[src];
    }
  });
  
  entryPoint.writeAsStringSync(document.outerHtml);
  
  var success = true;
  urlMap
  .values
  .forEach((assetName){
    success = success && new File("$output/$assetName").existsSync();  
  });  
  
  completer.complete(success);
  return completer.future;
}

Future<bool> _fixUrls(TaskContext ctx, String outputEntryPoint) {
  
}