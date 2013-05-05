library webui_tasks;

import 'dart:io';
import 'dart:async';
import 'package:bot/bot.dart';
import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart';
import 'package:html5lib/parser.dart';
import 'package:html5lib/dom.dart';

class WebuiTargetType {
  final String _value;
  const WebuiTargetType._internal(this._value);
  String toString() => 'CompilerTargetType.$_value';
  String get fileExt => _value;

  static const JS = const WebuiTargetType._internal('js');
  static const DART = const WebuiTargetType._internal('dart');
  static const MINIDART = const WebuiTargetType._internal('minidart');
}

Task createWebui2DartTask(String entryPoint, {String outputPath:"output", WebuiTargetType outputType:WebuiTargetType.DART}) {
  requireArgument(outputType == WebuiTargetType.MINIDART || outputType == WebuiTargetType.DART, 'outputType');
  
  final entryPointPath = new Path(entryPoint);
  final entryPointFile = new File.fromPath(entryPointPath);
  final entryPointFileName = entryPointPath.filename;
  final packageDir = new Directory('packages');
  
  assert(packageDir.existsSync());
  assert(entryPointFile.existsSync() && entryPoint.endsWith(".html"));
  
  return new Task.async((TaskContext context){
    return _dwc(context, outputPath, entryPoint).whenComplete((){
      context.info("Compiled Webui at: $outputPath");
        return _copy_out(context, outputPath, entryPointPath.directoryPath, entryPointFileName);
    });
  });
}

Future<bool> _dwc(TaskContext ctx, String output, String entryPoint){
  final packageDir = new Directory('packages');
  assert(packageDir.existsSync());
  
  final args = ["--package-root=${packageDir.path}/",
                "packages/web_ui/dwc.dart",
                "--out",
                "$output/",
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

Future<bool> _copy_out(TaskContext ctx, String output, String source, String entryPointFileName, {WebuiTargetType outputType: WebuiTargetType.DART}) {
  
  Completer completer = new Completer();
  
  var entryPoint = new File("$output/$entryPointFileName");
  var outputPath = new Path(output);
  
  assert(entryPoint.existsSync());
  
  var document = parse(entryPoint.readAsStringSync());
  
  var elementS = document.queryAll("script");
  
  document
  .queryAll("script")
  .forEach((element){
    String src = element.attributes["src"];
    src = src.replaceAll("../$source/", "");
    if(!src.contains(".dart")){
        var assetPath = src.startsWith("packages/") ? new Path(src) : new Path("$source/$src");
        var assetFile = new File.fromPath(assetPath);
        var asset = assetFile.readAsStringSync();
        var copyFile = new File.fromPath(outputPath.append(assetPath.filename));
        copyFile.writeAsStringSync(asset);
        element.attributes["src"] = assetPath.filename;
    } else if(outputType == WebuiTargetType.JS){
      element.attributes["src"] = "$src.js";
    }
  });
  
  document
  .queryAll("link")
  .forEach((element){
    String href = element.attributes["href"];
    element.attributes["href"] = href.replaceAll("../$source/", "");
  });
  
  entryPoint.writeAsStringSync(document.outerHtml);
  
  completer.complete(true);
  return completer.future;
}
