module SvgPrinter

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

lrel[str,str] edgePairs = [];

str generateSvg(Graph g, list[Edge] e){
    edgePairs = [];
    width = toInt(g.attributes["max_x"]);
    height = toInt(g.attributes["max_y"]);
    bgcolor = getAttribute(g.attributes, "bgcolor", "white");
    bool directed = fromString(g.attributes["directed"]);
    bool strict = fromString(g.attributes["strict"]);

    return "
    \<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"<width>pt\" height=\"<height>pt\" viewBox=\"0.00 0.00 <width>.00 <height>.00\"\>
    \<g id=\"graph0\" class=\"graph\" transform=\"scale(1 1) rotate(0) translate(0 0)\"\>
    \<title\><g.name>\</title\>
    \<polygon fill=\"<bgcolor>\" stroke=\"none\" points=\"0,0 0,<height> <width>,<height> <width>,0  0,0\"/\>

    <for ( /subgraph:graph(_,_,_,_) := g.subgraphs){>
        <printSubgraph(subgraph)>
    <}>

    <for ( /graph_node:graphNode(_,_) := g){>
        <printNode(graph_node)>
    <}>
    
    <for ( /edge:edge(_,_,_) := e){>
        <printEdge(edge,directed,strict)>
    <}>

    \</g\>
    \</svg\>

    ";
}

str printEdge(Edge e, bool directed, bool strict) {
    println(edgePairs);
    pair = <e.node_1.name,e.node_2.name>;
    n = size([p | p <- edgePairs, p == pair]);
    if (strict && pair in edgePairs) {return "";}

    color = getColor(e.attributes);
    fill = getFill(e.attributes,color);
    penwidth = getAttribute(e.attributes, "penwidth", "1.0");
    
    

    cx_1 = toInt(e.node_1.attributes["cx"]); rx_1 = toInt(e.node_1.attributes["rx"]);
    cy_1 = toInt(e.node_1.attributes["cy"]); ry_1 = toInt(e.node_1.attributes["ry"]);

    cx_2 = toInt(e.node_2.attributes["cx"]); rx_2 = toInt(e.node_2.attributes["rx"]);
    cy_2 = toInt(e.node_2.attributes["cy"]); ry_2 = toInt(e.node_2.attributes["ry"]);



    start_x = cx_1 - 5; end_x = cx_1 + 5;
    start_y = cy_1 - ry_1; end_y = start_y;
    curve_x = cx_1; curve_y = cy_1 - ry_1 - 30;

    dx = cx_2 - cx_1;
    dy = cy_2 - cy_1;

    if (!(dx == 0 && dy == 0) ) {
        d = sqrt((dx*dx) + (dy*dy));
        
        ux = dx / d;
        uy = dy / d;

        t_1 = 1 / ( sqrt( pow((ux/rx_1),2) + pow((uy/ry_1),2) ) );
        t_2 = 1 / ( sqrt( pow((ux/rx_2),2) + pow((uy/ry_2),2) ) );

        start_x = round(cx_1 + (t_1 * ux));
        start_y = round(cy_1 + (t_1 * uy));
        end_x = round(cx_2 - (t_2 * ux));
        end_y = round(cy_2 - (t_2 * uy));

        curve_x = start_x; curve_y = start_y;
    } 

    if (pair in edgePairs) {
        if (dx == 0 && dy == 0) {
                curve_y = curve_y + (5*n); 
        } else {
            nextCoords = getNextCoords(start_x,start_y,cx_1,cy_1,rx_1,ry_1,n);
            start_x = nextCoords[0]; start_y = nextCoords[1];

            nextCoords = getNextCoords(end_x,end_y,cx_2,cy_2,rx_2,ry_2,n);
            end_x = nextCoords[0]; end_y = nextCoords[1];
                      
            curve_x = start_x; curve_y = start_y; 
        }

    }   

    edgePairs = edgePairs + pair;
    if (!directed) { edgePairs = edgePairs + <pair[1],pair[0]>;}
    println(edgePairs);
    return "
    \<g id=\"\" class=\"edge\"\>
    \<title\><e.node_1.name>-<e.node_2.name>-<n>\</title\>
    \<path fill=\"<fill>\" stroke=\"<color>\" stroke-width=\"<penwidth>\" d=\"M <start_x>,<start_y> C <start_x>,<start_y> <curve_x>,<curve_y> <end_x>,<end_y> \"/\>
    <if (directed) {>
    \<polygon fill=\"<color>\" stroke=\"<color>\" points=\"<end_x>,<end_y> <end_x - 5>,<end_y - 5> <end_x - 5>,<end_y + 5>\"/\>
    <}>
    \</g\>
    ";
}

str printNode(GraphNode n) {

    color = getColor(n.attributes);
    fill = getFill(n.attributes,color);
    penwidth = getAttribute(n.attributes, "penwidth", "1.0");
    fontsize = getAttribute(n.attributes, "fontsize", "14.0");
    fontname = getAttribute(n.attributes, "fontname", "Times");
    str label = getAttribute(n.attributes, "label", n.name);


    cx = n.attributes["cx"];
    cy = n.attributes["cy"];
    rx = n.attributes["rx"];
    ry = n.attributes["ry"];
    
    return "
    \<g id=\"<n.name>\" class=\"node\"\>
    \<title\><n.name>\</title\>
    \<ellipse fill=\"<fill>\" stroke=\"<color>\" stroke-width=\"<penwidth>\" cx=\"<cx>\" cy=\"<cy>\" rx=\"<rx>\" ry=\"<ry>\"/\>
    \<text text-anchor=\"middle\" x=\"<cx>\" y=\"<toInt(cy)+5>\" font-family=\"<fontname>\" font-size=\"<fontsize>\"\><label>\</text\>
    \</g\>
    ";
}

str printSubgraph(Graph g) {

    color = getColor(g.attributes);
    fill = getFill(g.attributes,color);
    penwidth = getAttribute(g.attributes, "penwidth", "1.0");
    fontsize = getAttribute(g.attributes, "fontsize", "14.0");
    fontname = getAttribute(g.attributes, "fontname", "Times");
    str label = getAttribute(g.attributes, "label", g.name);
    
    
    initial_x = toInt(g.attributes["initial_x"]);
    initial_y = toInt(g.attributes["initial_y"]);
    max_x = toInt(g.attributes["max_x"]);
    max_y = toInt(g.attributes["max_y"]);

    
    return "
    \<g id=\"<g.name>\" class=\"cluster\"\>
    \<title\><g.name>\</title\>
    \<polygon fill=\"<fill>\" stroke=\"<color>\" stroke-width=\"<penwidth>\" points=\"<initial_x>,<initial_y> <initial_x>,<max_y> <max_x>,<max_y> <max_x>,<initial_y>\"/\>
    \<text text-anchor=\"middle\" x=\"<(max_x + initial_x)/2>\" y=\"<initial_y + 25>\" font-family=\"<fontname>\" font-size=\"<fontsize>\"\><label>\</text\>
    \</g\>
    ";
}

str getColor(map[str,str] a) {
    color = "black";
    if ("pencolor" in a) {
        color = a["pencolor"];
    } else if ("color" in a) {
        color = a["color"];
    } 
    return color;
}

str getFill(map[str,str] a, str color) {
    fill = "none";
    if ("style" in a && a["style"] == "filled") {
        if ("fillcolor" in a) {
            fill = a["fillcolor"];
        } else {
            fill = color;
        }

    }
    return fill;
}

str getAttribute(map[str,str] a, str attr, str def) {
    ret = def;
    if (attr in a) {
        ret = a[attr];
    }
    return ret;
}

tuple[int,int] getNextCoords(int x, int y, int cx, int cy, int rx, int ry, int n) {

    x = x - cx;
    y = y - cy;

    if (x > 0) {
        x = x - (2*n);
    } else {
        x = x + (2*n);
    }
    
    sign = 1;
    if (y < 0) { sign = -1;}
    y = round(ry * sign * sqrt(1-(pow(x,2)/pow(rx,2))));
    x = x + cx;
    y = y + cy;
    return <x,y>;
}