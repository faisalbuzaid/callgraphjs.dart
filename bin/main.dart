import 'flowgraph.dart';
import 'package:parsejs/parsejs.dart';
import 'dart:io';
import 'natives.dart';

void main(List<String> args) {
  String filename = args[0];
  new File(filename).readAsString().then((String code) {
    Program ast = parsejs(code, filename: filename);
    FlowGraph flowGraph = buildFlowGraph(ast);
    addNatives(flowGraph);
    
    new File('flowgraph.dot').writeAsString(flowGraph.toDot());
    
    String functionName(target) {
      if (target is String) return target;
      FunctionNode node = target;
      if (node.name != null) {
        return node.name.value;
      }
      if (node.parent is FunctionExpression && node.parent.parent is AssignmentExpression) {
        AssignmentExpression assign = node.parent.parent;
        if (assign.left.line == node.line) {
          return code.substring(assign.left.start, assign.left.end).replaceAll('.prototype.', '::');
        }
      }
      return '<anon>:${node.line}';
    }
    
    findCalls(Node node) {
      if (node is CallExpression) {
        List targets = flowGraph.findCallTargets(node);
        print("${node.location}: ${targets.map(functionName).join(', ')}");
      }
      node.forEach(findCalls);
    }
    
    findCalls(ast);
  });
}

