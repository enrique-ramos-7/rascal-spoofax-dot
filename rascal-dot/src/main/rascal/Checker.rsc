module Checker

extend analysis::typepal::TypePal;

import String;
import Syntax;
import lang::std::Layout;

data AType 
= colorType()
| fontType()
| doubleType()
| stringType()
| nodeType()
;

data IdRole
= nodeId()
| attributeId()
| valueId()
;


str prettyAType(colorType()) = "color";
str prettyAType(doubleType()) = "double";
str prettyAType(stringType()) = "string";
str prettyAType(fontType()) = "font";

data ScopeRole = graphScope();
data GraphInfo = graphInfo(bool strict, bool directed,lrel[str,str] edgePairs);

set[str] colors = {"red", "orange", "yellow", "green", "blue", "inidigo", "violet", "black", "white", "grey"};
set[str] fonts = { "times", "helvetica", "arial", "comic sans ms"};
set[str] values = colors + fonts;
set[str] numericAttributes = {"penwidth", "fontsize"};
set[str] colorAttributes = {"color", "bgcolor", "fillcolor", "pencolor"};
set[str] stringAttributes = {"style", "label"};



//Top level graph
void collect(current:(Graph) `graph <Identifier? graph_id> { <Stmt_list? stmt_list> }`, Collector c) {
    c.enterScope(current);
        c.setScopeInfo(c.getScope(), graphScope(), graphInfo(false,false,[]));
        collect(stmt_list, c);
    c.leaveScope(current);
}
void collect(current:(Graph) `strict graph <Identifier? graph_id> { <Stmt_list? stmt_list> }`, Collector c) {
    c.enterScope(current);
        c.setScopeInfo(c.getScope(), graphScope(), graphInfo(true,false,[]));
        collect(stmt_list, c);
    c.leaveScope(current);
}

void collect(current:(Graph) `digraph <Identifier? graph_id> { <Stmt_list? stmt_list> }`, Collector c) {
    c.enterScope(current);
        c.setScopeInfo(c.getScope(), graphScope(), graphInfo(false,true,[]));
        collect(stmt_list, c);
    c.leaveScope(current);
}

void collect(current:(Graph) `strict digraph <Identifier? graph_id> { <Stmt_list? stmt_list> }`, Collector c) {
    c.enterScope(current);
        c.setScopeInfo(c.getScope(), graphScope(), graphInfo(true,true,[]));
        collect(stmt_list, c);
    c.leaveScope(current);
}

//Stmt_list
void collect(current: (Stmt_list) `<Stmt stmt> <Stmt_list? stmt_list>`, Collector c) {
    collect(stmt,stmt_list,c);
}

void collect(current: (Stmt_list) `<Stmt stmt> ; <Stmt_list? stmt_list>`, Collector c) {
    collect(stmt,stmt_list,c);
}


void collect(current: (Subgraph) `subgraph <Identifier? id> { <Stmt_list stmt_list> }`, Collector c) {
    c.enterScope(current);
        collect(stmt_list, c);
    c.leaveScope(current);
}


//Stmt
void collect(current: (Stmt) `<Identifier id_1> = <Identifier id_2>`, Collector c) {
    handleAttribute(current,id_1,id_2,c);
}

void collect(current: (Stmt) `<Node_stmt node_stmt>`, Collector c) {
    collect(node_stmt, c);
}


void collect(current: (Node_stmt) `<Identifier id> <Port? _> <Attr_list? attr_list>`, Collector c) { // Node statment
    c.define(replaceAll("<id>","\"",""), nodeId(), current, defType(nodeType()));
    collect(attr_list,c);
}


//Attributes
void collect(current: (Attr_list) `[<A_list? a_list>] <Attr_list? attr_list>`, Collector c) { // Node statment
    collect(a_list,attr_list,c);
}

void collect(current: (A_list) `<Identifier id_1> = <Identifier id_2>  <A_list? a_list>`, Collector c) { 
    handleAttribute(current,id_1,id_2,c);
    collect(a_list,c);
}

void collect(current: (A_list) `<Identifier id_1> = <Identifier id_2> ; <A_list? a_list>`, Collector c) {
    handleAttribute(current,id_1,id_2,c);
    collect(a_list,c);
}

void collect(current: (A_list) `<Identifier id_1> = <Identifier id_2> , <A_list? a_list>`, Collector c) { 
    handleAttribute(current,id_1,id_2,c);
    collect(a_list,c);
}

//Edges 
void collect(current: (Edge_stmt) `<Identifier id> <Port? _> <EdgeRHS rhs> <Attr_list? attr_list>`, Collector c) {
    c.use(id, {nodeId()});
    c.push("edgeNode",id);
    collect(rhs,attr_list,c);
}

void collect(current: (EdgeRHS) `-- <Identifier id> <Port? _> <EdgeRHS? rhs>`, Collector c) {
    lastNode = c.pop("edgeNode");

    for (<s,scopeInfo> <- c.getScopeInfo(graphScope())) {

        if (graphInfo(strict,directed,edgePairs) := scopeInfo) {

            if (directed) {
                c.report(error(current,"Edges of the form \'--\' not allowed in directed graphs"));                
            }

            if (strict && <"<lastNode>","<id>"> in edgePairs) {
                c.report(warning(current,"Strict graphs do not allow multi-edges"));                
            }

            newEdgePairs = edgePairs + <"<lastNode>","<id>">;
            if (!directed) {newEdgePairs = newEdgePairs +  <"<id>","<lastNode>">;}
            c.setScopeInfo(s,graphScope(),graphInfo(strict,directed,newEdgePairs));
        }
    }

    c.use(id, {nodeId()});
    c.push("edgeNode",id);
    collect(rhs,c);
}

void collect(current: (EdgeRHS) `-\> <Identifier id> <Port? _> <EdgeRHS? rhs>`, Collector c) {
    lastNode = c.pop("edgeNode");

    for (<s,scopeInfo> <- c.getScopeInfo(graphScope())) {

        if (graphInfo(strict,directed,edgePairs) := scopeInfo) {

            if (!directed) {
                c.report(error(current,"Edges of the form \'-\>\' not allowed in directed graphs"));                
            }

            if (strict && <"<lastNode>","<id>"> in edgePairs) {
                c.report(warning(current,"Strict graphs do not allow multi-edges"));                
            }

            newEdgePairs = edgePairs + <"<lastNode>","<id>">;
            if (!directed) {newEdgePairs = newEdgePairs +  <"<id>","<lastNode>">;}
            c.setScopeInfo(s,graphScope(),graphInfo(strict,directed,newEdgePairs));
        }
    }

    c.use(id, {nodeId()});
    c.push("edgeNode",id);
    collect(rhs,c);
}


void handleAttribute(Tree current, Tree id_1, Tree id_2, Collector c) {

    switch(id_2) {
        case (Identifier) `"<String s>"`: id_2 = s;
    }
    collect(id_2,c);

    c.use(id_1,{attributeId()});
    c.use(id_2,{valueId()});

    c.requireSubType(id_2, id_1, error(current, "Value %t does not match attribute of type %t", id_2,id_1));
}

// Identifiers
void collect(current: (Identifier) `<Alphanum id>`, Collector c) {
    if (!("<id>" in values)) {
        c.define("<id>", valueId(), current, defType(stringType()));
    }

}

void collect(current: (String) `<String id>`, Collector c) {
    if (!("<id>" in values)) {
        c.define("<id>", valueId(), current, defType(stringType()));
    }

}

void collect(current: (Identifier) `<Numeral id>`, Collector c) {
        c.define("<id>", valueId(), current, defType(doubleType()));
}


TModel getTModel(Tree t) {
    if (t has top) t = t.top;

    bool dotIsSubType(AType l, AType r ) {
        
        switch (<l,r>) {
            case <colorType(),stringType()>:
                return true;
            case <fontType(),stringType()>:
                return true;
            case <l,l>: //True if both same
                return true;
            default:
                return false;
        }
    }

    bool dotMayOverload (set[loc] defs, map[loc, Define] defines) {
        roles = {defines[def].idRole | def <- defs};   
        return roles == {nodeId()} || roles == {valueId()};    
    }

    TypePalConfig config = tconfig( 
        isSubType = dotIsSubType,
        mayOverload = dotMayOverload
    );

    c = newCollector("check", t, config);
    predefineInit(t,c);
    collect(t,c);
    return newSolver(t, c.run()).run();
}

void predefineInit(Tree t, Collector c) {


    predefineAs(colors, valueId(), colorType(), t, c);
    predefineAs(fonts, valueId(), fontType(), t, c);
    predefineAs(numericAttributes, attributeId(), doubleType(), t, c);
    predefineAs(colorAttributes, attributeId(), colorType(), t, c);
    predefineAs({"fontname"}, attributeId(), fontType(), t, c);
    predefineAs(stringAttributes, attributeId(), stringType(), t, c);
}

void predefineAs(set[str] id_set, IdRole role, AType p_type, Tree t, Collector c) {
    for (id <- id_set) {
        c.predefine(id, role, t.src, defType(p_type));
    }
}
