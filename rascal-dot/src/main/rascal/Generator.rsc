module Generator

import IO;
import ParseTree;
import vis::Text;
import lang::std::Layout;
import Syntax;
import Map;
import List;
import String;
import util::Math;
import Boolean;
import DataTypes;
import LayoutGenerator;
import SvgPrinter;



str generator(Tree t) {
    Graph graph = getGraph(t);
    graph = getLayout(graph,<0,0>);
    println(graph);
    list[Edge] allEdges = getEdges(t,graph);
    println(allEdges);
    str svg = generateSvg(graph, allEdges);

    return svg;

}



list[Edge] getEdges(Tree t, Graph main_graph) {
    allEdges = [];

    visit(t) {
        case (Edge_stmt) `<Identifier id> <Port? _> <EdgeRHS rhs> <Attr_list? attr_list>`:
            {
                attributes = extractAttributes(attr_list); 
                for (new_edge <- [new_edge | new_edge <- generateEdges("<id>",rhs,attributes,main_graph)]) {
                    allEdges = allEdges + new_edge;
                }
            }
    } 
    
    return allEdges;
}

list[Edge] generateEdges(str id_1, Tree rhs, map[str,str] attributes, Graph main_graph) {
    edges = [];

    top-down-break visit(rhs) {
        case (EdgeRHS) `-- <Identifier id_2> <Port? _> <EdgeRHS? new_rhs>`:
            edges = edges + edge(getNode("<id_1>",main_graph), getNode("<id_2>",main_graph),attributes) + generateEdges("<id_2>", new_rhs, attributes,main_graph);
        
        case (EdgeRHS) `-\> <Identifier id_2> <Port? _> <EdgeRHS? new_rhs>`:
            edges = edges + edge(getNode("<id_1>",main_graph), getNode("<id_2>",main_graph),attributes) + generateEdges("<id_2>", new_rhs, attributes,main_graph);
    }

    return edges;
}

GraphNode getNode(str name, Graph g) {
    visit(g) {
        case n: graphNode(name,_): return n;
    }
    return graphNode("",()); // should not happen, probably ought to error handle properly
}

map[str,GraphNode] updateNodeScope(map[str,GraphNode] scope, list[GraphNode] nodes) {
    for (n <- nodes) {
        scope[n.name] = n;
    }
    return scope;
}

Graph getGraph(Tree t) {
    Graph main_graph = graph("",[],[],());
    set[str] allNodes = {};
    str directed = "false";
    str strict = "false";


    top-down-break visit(t) {
        case (Graph) `graph <Identifier? graph_id> { <Stmt_list? stmt_list> }`:
            {directed = "false"; strict = "false"; main_graph = generateSubgraph("<graph_id>", stmt_list, {});}
        case (Graph) `digraph <Identifier? graph_id> { <Stmt_list? stmt_list> }`:
            {directed = "true"; strict = "false";  main_graph = generateSubgraph("<graph_id>", stmt_list, {});}
        case (Graph) `strict graph <Identifier? graph_id> { <Stmt_list? stmt_list> }`:
            {directed = "false"; strict = "true";  main_graph = generateSubgraph("<graph_id>", stmt_list, {});}
        case (Graph) `strict digraph <Identifier? graph_id> { <Stmt_list? stmt_list> }`:
            {directed = "true"; strict = "true";  main_graph = generateSubgraph("<graph_id>", stmt_list, {});}

    }

    visit(t) { // Add attributes to nodes
        case (Node_stmt) `<Identifier id> <Port? _> <Attr_list? attr_list>`:
        {
            str name = "<id>";
            main_graph = visit(main_graph) {
                case graphNode(name,attr) => graphNode("<id>",mergeAttributes(attr,extractAttributes(attr_list)))
            }
        }
    }


    main_graph.attributes["directed"] = directed;
    main_graph.attributes["strict"] = strict;
    return main_graph;
}

Graph generateSubgraph(str name, Stmt_list? stmt_list, set[str] allNodes) {
    Graph subgraph = graph(name,[],[],());

    top-down-break visit(stmt_list) { 
        case (Subgraph) `subgraph <Identifier? id> { <Stmt_list? stmt_list> }`:
            print(""); //This is just here so that we break on subgraphs and don't collect attributes from them
        case (Stmt) `<Identifier id_1> = <Identifier id_2>`:
            subgraph.attributes = subgraph.attributes + ("<id_1>":replaceAll("<id_2>","\"",""));
    }

    top-down-break visit(stmt_list) { // Visit all subgraph, break so don't go past
        case (Subgraph) `subgraph <Identifier? id> { <Stmt_list? stmt_list> }`: 
        {
            subgraph.subgraphs = subgraph.subgraphs + generateSubgraph("<id>",stmt_list, allNodes);

            visit (subgraph) { // retrieve nodes from subgraph, no duplicates
                case n : graphNode(_,_):
                    allNodes = allNodes + n.name;
            }
        }     
    }

    subgraph = visit(subgraph) { // lower subgraphs inherit attributes unless they have their own
        case graph(a,b,c,attr) => graph(a,b,c,mergeAttributes(subgraph.attributes,attr))
    }

    
    top-down-break visit(stmt_list) { // collect any new nodes
        case (Subgraph) `subgraph <Identifier? id> { <Stmt_list? stmt_list> }`:
            print(""); //This is just here so that we break on subgraphs and don't collect nodes from them
        case (Node_id) `<Identifier id> <Port? _>`:
            if (!("<id>" in allNodes)) {
                GraphNode new_node = graphNode("<id>",());
                subgraph.nodes = subgraph.nodes + new_node;
                allNodes = allNodes + "<id>";
            } 
    }


    return subgraph;
}

map[str,str] extractAttributes (Attr_list? a) {
    println("attr_list");
    println(a);
    attributes = ();

    visit(a) {
        case (Attr_list) `[ <A_list? a_list> ] <Attr_list? _>`:
            attributes = mergeAttributes(attributes,extractAttributes(a_list));
    }

    return attributes;

}
map[str,str] extractAttributes (A_list? a) {
    println("a_list");
    attributes = ();

    println(a);
    visit(a) {
        case (A_list) `<Identifier id_1> = <Identifier id_2>  <A_list? _>`:
            attributes = mergeAttributes(attributes,("<id_1>":replaceAll("<id_2>","\"","")));
            
        case (A_list) `<Identifier id_1> = <Identifier id_2> ; <A_list? _>`:
            attributes = mergeAttributes(attributes,("<id_1>":replaceAll("<id_2>","\"","")));
            
        case (A_list) `<Identifier id_1> = <Identifier id_2> , <A_list? _>`:
            attributes = mergeAttributes(attributes,("<id_1>":replaceAll("<id_2>","\"","")));
    }

    return attributes;

}

map[str,str] mergeAttributes(map[str,str] a, map[str,str] b) {
    set[str] keys = domain(a) + domain(b); 
    map[str,str] merge = ();

    for (k <- keys) {
        if (k in b) {
            merge[k] = b[k];
        } else {
            merge[k] = a[k];
        } 
    }
    println("Merge of <a> and <b> returned <merge>");
    return merge;
}