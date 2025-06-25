module Syntax

import IO;
import ParseTree;
import vis::Text;
import lang::std::Layout;



// lexical Whitespace = [\ \t\n\r]* !>> [\ \t\n\r];
// lexical Comment = "//" ![\n\r]* $;
// layout Layout = Whitespace | Comment;

keyword Keywords = 'node' | 'edge' | 'graph' | 'digraph' | 'subgraph' | 'strict';
lexical Identifier = Alphanum | Numeral | "\"" String "\"";
lexical Alphanum = ([a-zA-Z_][a-zA-Z0-9_]*) !>> [a-zA-Z0-9_] \Keywords; //TODO Also numerals and strings
lexical Numeral =  ( "-"? ( ("."[0-9]+) | ([0-9]+("."[0-9]*)?) ) ) !>> [0-9] \Keywords;
lexical String = (![\"] | "\\" << "\"")* ;



start syntax DOT 
    = Graph
    ;

syntax Graph
    = "strict"? ("graph" | "digraph") Identifier? "{" Stmt_list? "}"
    ;

syntax Stmt_list
    = Stmt ";"? Stmt_list?
    ;

syntax Stmt
    = Node_stmt
    | Edge_stmt
    | Attr_stmt
    | Identifier "=" Identifier
    | Subgraph
    ;

syntax Attr_stmt 
    = ("graph" | "node" | "edge") Attr_list
    ;

syntax Attr_list
    = "[" A_list? "]" Attr_list?
    ;

syntax A_list
    = Identifier '=' Identifier (";"|",")? A_list?
    ;

syntax Edge_stmt
    = (Node_id | Subgraph) EdgeRHS Attr_list?
    ;

syntax EdgeRHS
    = ("--"|"-\>") (Node_id | Subgraph) EdgeRHS?
    ;

syntax Node_stmt
    = Node_id Attr_list?
    ;

syntax Node_id
    = Identifier Port?
    ;

syntax Port
    = ":" Identifier (":" Compass_pt)?
    | ":" Compass_pt
    ;

syntax Subgraph
    = ("subgraph" Identifier?)? "{" Stmt_list? "}"
    ;

syntax Compass_pt
    = "n" | "ne" | "e" | "se" | "s" | "sw" | "w" | "nw" | "_";