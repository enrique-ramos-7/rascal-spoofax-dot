# DOT IN SPOOFAX
This folder contains all files for the Spoofax implementation of *DOT*. This implementation is inteded to be run **in Eclipse with the Spoofax plugin.**

## Running DOT
To generate SVGs from *DOT* code, open a .dot file and go to Spoofax -> Transformation -> to svg in the toolbar. This should generate a new SVG from the .dot file (you might need to reload the svg window if you're using the Eclipse to view it). Errors and warnings in .dot files should appear on their own.

## Implementaiton overview
- syntax/dot.sdf3 contains the syntax definiton using the SDF3 language, used to generate an AST from *DOT* source code
- trans/dot.str is the main Stratego file for transforming the graph into an intermidate representation
- trans/gen/generator.str contains code for getting a graph represenation from the AST 
- trans/gen/layout.str adds layout information to the graph
- trans/gen/svg.str prints an svg from the graph
- trans/gen/statix.stx contain validation code for the implementation in the Statix languge
- editor/Main.esv configures the toolbar to have a button for generating svgs
