part of webui_tasks;

/*
 * Copies linked static assets referenced from the main entry point of the webui application to the [outputPath].
 * [entryPoint] is the path to the main entry point of the webui application.  
 * [outputPath] defaults to [project_root/output] unless one is provided. 
 */

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

Future<bool> _copy_out(TaskContext ctx, String output, String sourceDir, String entryPointFileName) {
  
  Completer completer = new Completer();
  
  var entryPoint = new File("$sourceDir/$entryPointFileName");
  var outputPath = new Path(output);
  
  assert(entryPoint.existsSync());
  
  var document = parse(entryPoint.readAsStringSync());
  var assetList = [];
  
  document
  .queryAll("script")
  .forEach((element){
    String src = element.attributes["src"];
    ctx.fine(src);
    if(!src.contains(".dart")){
        var assetPath = src.startsWith("packages/") ? new Path(src) : new Path("$sourceDir/$src");
        var assetFile = new File.fromPath(assetPath);
        var asset = assetFile.readAsStringSync();
        var copyFile = new File.fromPath(outputPath.append(assetPath.filename));
        copyFile.writeAsStringSync(asset);
        assetList.add(assetPath.filename);
    } 
  });
  
  var success = true;
  
  assetList
  .forEach((assetName){
    success = success && new File("$output/$assetName").existsSync();
  });
  
  completer.complete(success);
  return completer.future;
}