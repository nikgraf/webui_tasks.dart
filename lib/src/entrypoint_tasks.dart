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
 */

Task createWebui2DartTask(String entryPoint, {String outputPath:"output", bool rewriteUrls:false}) {
  
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

/*
 * Wrapper for the DWC compiler whose final product is a minified compiled Dart entry point.
 * [entryPoint] is the path to the main entry point of the webui application.  
 * [outputPath] defaults to [project_root/output] unless one is provided.  
 * [rewriteUrls] determines whether to pass --rewrite-urls or --no-rewrite-urls to the dwc compiler.
 */

ChainedTask createWebui2MiniDartTask(String entryPoint, {String outputPath:"output", bool rewriteUrls:false}) {
  
  final entryPointPath = new Path(entryPoint);
  final entryPointFile = new File.fromPath(entryPointPath);
  final entryPointFileName = entryPointPath.filename;
  final packageDir = new Directory('packages');
  
  assert(packageDir.existsSync());
  assert(entryPointFile.existsSync() && entryPoint.endsWith(".html"));
  
  Task w2d = createWebui2DartTask(entryPoint, outputPath:outputPath, rewriteUrls:rewriteUrls);
  Task d2d = createDartCompilerTask(["$outputPath/${entryPointFileName}_bootstrap.dart"], outputType:CompilerTargetType.DART);
  addTask("w2d_j", w2d);
  return w2d.chain("w2d_j").and("d2d", d2d);
}

/*
 * Wrapper for the DWC compiler whose final product is a Javascript compiled entry point.
 * [entryPoint] is the path to the main entry point of the webui application.  
 * [outputPath] defaults to [project_root/output] unless one is provided.  
 * [rewriteUrls] determines whether to pass --rewrite-urls or --no-rewrite-urls to the dwc compiler.
 */

ChainedTask createWebui2JsTask(String entryPoint, {String outputPath:"output", bool rewriteUrls:false}) {
  final entryPointPath = new Path(entryPoint);
  final entryPointFile = new File.fromPath(entryPointPath);
  final entryPointFileName = entryPointPath.filename;
  final packageDir = new Directory('packages');
  
  assert(packageDir.existsSync());
  assert(entryPointFile.existsSync() && entryPoint.endsWith(".html"));
  
  Task w2d = createWebui2DartTask(entryPoint, outputPath:outputPath, rewriteUrls:rewriteUrls);
  Task d2js = createDart2JsTask(["$outputPath/${entryPointFileName}_bootstrap.dart"], liveTypeAnalysis: true, rejectDeprecatedFeatures: true);
  addTask("w2d_md", w2d);
  return w2d.chain("w2d_md").and("d2js", d2js);
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
        ctx.fine("$exitCode");
        return exitCode==0;
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
  final entryPointPath = new Path(compiledEntryPoint);
  final entryPoint = entryPointPath.filename;
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
      if(outputType == WebuiTargetType.MINIDART) {
        element.attributes["src"] = "$staticPath${entryPoint}_bootstrap.compiled.dart";
        ctx.fine("$staticPath${entryPoint}_bootstrap.compiled.dart");
      }
      if(outputType == WebuiTargetType.JS) {
        element.attributes["src"] = "$staticPath${entryPoint}_bootstrap.dart.js";
        ctx.fine("$staticPath${entryPoint}_bootstrap.dart.js");
      }
    }
  });
  
  compiledEntry.writeAsStringSync(document.outerHtml);
  ctx.info("Fixed Urls at entrypoint $compiledEntryPoint");
  completer.complete(true);
  return completer.future;
}