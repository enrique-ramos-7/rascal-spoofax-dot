module Plugin

import IO;
import ParseTree;
import util::Reflective;
import util::IDEServices;
import util::LanguageServer;
import lang::std::Layout;
import Relation;
import Syntax;
import Generator;
import Checker;

data Command = gen(DOT d);



set[LanguageService] contribs() = { 
    parsing(ParseTree::parser(#start[DOT])),
    analysis(dotAnalysis),
    codeLens(lrel[loc src, Command lens] (start[DOT] d) {
        return [<d.src, gen(d.top, title="Generate svg")>];
    }),
    execution(exec)
};

value exec(gen(DOT d)) {
    svg = generator(d);
    outputFile = |project://rascal-dot/target.svg|;
    writeFile(outputFile, svg);
    edit(outputFile);
    return ("result": true);
}


Summary dotAnalysis(loc l, start[DOT] input) {
    tm = getTModel(input);
    defs = getUseDef(tm);
    messages = {<m.at,m> | m <- getMessages(tm), !(m is info)};
    return summary(l, messages = messages, definitions = defs);
}

void main() {
    //NOTE: typepal-0.15.1.jar!/ is typepal-0.15.1.jar!/src in the default pathConfig. THIS DETAIL LOST ME A DAY BECAUSE IT DIDN'T WORK!!! Don't forget.
    list[loc] srcs = [|project://rascal-dot/src/main/rascal|, |jar+file:///C:/Users/ramos/.m2/repository/org/rascalmpl/typepal/0.15.1/typepal-0.15.1.jar!/|];
    list[loc] libs = [|lib://rascal|];
    PathConfig pcfg = pathConfig();
    pcfg.srcs = srcs;
    pcfg.libs = libs;

    println(pcfg);
    Language dot = language(pcfg, "DOT", {"dot"}, "Plugin", "contribs");
    registerLanguage(dot);
}