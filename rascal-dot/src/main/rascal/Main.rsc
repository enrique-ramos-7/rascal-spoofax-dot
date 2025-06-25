module Main

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
import Generator;
import Checker;




void main() {
    str source = readFile(|project://rascal-dot/example.dot|);
    t = parse(#DOT, source, |project://rascal-dot/example.dot|, allowAmbiguity=true);
    writeFile(|project://rascal-dot/target.svg|, generator(t));
    //t = parse(#Stmt_list,"A--B");
    //println(prettyTree(t));
    if (/amb({a1, a2}) := t) 
    println("alternative 1: <a1.prod> \n alternative 2: <a2.prod>");
}

