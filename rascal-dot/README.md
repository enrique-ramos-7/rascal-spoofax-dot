# DOT IN RASCAL
This folder contains all files for the Rascal implementation of *DOT*. This implementation is inteded to be run **in Vscode with the Rascal extension.**

## Running DOT
To generate SVGs from DOT code, you can run the main function in main/src/rascal/Plugin.rsc. You will need to replace `|jar+file:///C:/Users/ramos/.m2/repository/org/rascalmpl/typepal/0.15.1/typepal-0.15.1.jar!/|` with a path pointing to your own version of the typepal jar, which maven should have gotten for you. This should allow you to see errors an warnings on .dot files, in addition to a "generate svg" button. You can also run the main function in Main.rsc to generate an avg from a hardcoded *DOT* file (example.dot by default).

## Implementaiton overview
- Syntax.rsc contains the syntax defintion that is used to parse input
- Generator.rsc is used to convert a DOT parse tree into an intermediate ADT
- LayoutGenerator.rsc computes layout information for the graph
- SvgPrinter.rsc prints an SVG from a graph ADT
- Plugin.rsc defines a language server for the implementation
- Main.rsc generates an SVG from a given file
- Checker.rsc uses TypePal to validate DOT code
