library hop_runner;

import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart';

void main() {
  
  final paths = ['lib/webui_tasks.dart'];
  
  addTask('docs', createDartDocTask(paths, linkApi: true));
  
  addTask('analyze_libs', createDartAnalyzerTask(paths));
  
  runHop();
}