part of webui_tasks;

/* 
 * Adapted from [CompilerTargetType] courtesy of:  https://github.com/kevmoo/hop.dart/blob/master/lib/src/hop_tasks/dart2js.dart
*/
class WebuiTargetType {
  final String _value;
  const WebuiTargetType._internal(this._value);
  String toString() => 'CompilerTargetType.$_value';
  String get fileExt => _value;
  static const JS = const WebuiTargetType._internal('js');
  static const DART = const WebuiTargetType._internal('dart');
  static const MINIDART = const WebuiTargetType._internal('minidart');
}

/*
 * Wrapper for the DWC compiler.
 * [entryPoint] is the path to the main entry point of the webui application.  
 * [outputPath] defaults to [project_root/output] unless one is provided.  
 * [rewriteUrls] determines whether to pass --rewrite-urls or --no-rewrite-urls to the dwc compiler.
 * [outputType] can be either [WebuiTargetType.DART] or [WebuiTargetType.MINIDART].
 */

Task createWebui2DartTask(String entryPoint, {String outputPath:"output", bool rewriteUrls:false, WebuiTargetType outputType:WebuiTargetType.DART}) {
  requireArgument(outputType == WebuiTargetType.MINIDART || outputType == WebuiTargetType.DART, 'outputType');
  
  final entryPointPath = new Path(entryPoint);
  final entryPointFile = new File.fromPath(entryPointPath);
  final entryPointFileName = entryPointPath.filename;
  final packageDir = new Directory('packages');
  
  assert(packageDir.existsSync());
  assert(entryPointFile.existsSync() && entryPoint.endsWith(".html"));
  
  if(outputType == WebuiTargetType.DART) {
    return new Task.async((TaskContext context){
      return _dwc(context, outputPath, entryPoint, rewriteUrls).whenComplete((){
        context.info("Compiled Webui at: $outputPath");
      });
    });
  }
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

/*
 * Fixes urls to static assets to point to the specified [staticPath] directory as urls relative to the [compiledEntryPoint].
 * [compiledEntryPoint] is the path to the main entry point of the compiled application.  
 * [staticPath] is the path to static assets, relative to the [compiledEntryPoint].  [staticPath] defaults to "" unless one is provided (defaults to the same directory as the [compiledEntryPoint]).
 * [outputType] is of type [WebuiTargetType] and determines the extension of the bootstrap script.
 */

Task createFixUrlTask(String compiledEntryPoint, {String staticPath:"", WebuiTargetType outputType:WebuiTargetType.DART}) {
   if(!staticPath=="" && !staticPath.endsWith("/")) staticPath = "$staticPath/";
   return new Task.async((TaskContext context){
     return _fixUrls(context, compiledEntryPoint, staticPath, outputType);
   });
}

Future<bool> _fixUrls(TaskContext ctx, String compiledEntryPoint, String staticPath, WebuiTargetType outputType) {
  Completer completer = new Completer();
  final compiledEntry = new File(compiledEntryPoint);
  assert(compiledEntry.existsSync());
  
  var document = parse(compiledEntry.readAsStringSync());
  
  document
  .queryAll("script")
  .forEach((element){
    String src = element.attributes["src"];
    ctx.fine(src);
    var path = new Path(src);
    if(!src.contains(".dart")){
      ctx.fine(path.filename);
      element.attributes["src"] = "$staticPath${path.filename}";
    } else {
      if(WebuiTargetType.MINIDART) {
        element.attributes["src"] = "$staticPath${path.filename}_bootstrap.compiled.dart";
      }
      if(WebuiTargetType.JS) {
        element.attributes["src"] = "$staticPath${path.filename}_bootstrap.dart.js";
      }
    }
  });
  
  compiledEntry.writeAsStringSync(document.outerHtml);
  
  completer.complete(true);
  return completer.future;
}