module LayoutGenerator

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

Graph getLayout(Graph current_graph,tuple[int,int] coordinates) {
    println("<current_graph.name> with coords <coordinates>");
    margin = 50;
    coordinates[0] += margin; 
    coordinates[1] += margin; // Margin 
    current_graph.attributes["initial_x"] = "<coordinates[0]>"; // for drawing the subgraph box later 
    current_graph.attributes["initial_y"] = "<coordinates[1]>"; 

    int elements = size(current_graph.nodes) + size(current_graph.subgraphs);
    int grid_length = floor(sqrt(elements)); // If perfect square
    if (pow(floor(sqrt(elements)), 2) != elements) { //If not perfect square
        grid_length = floor(sqrt(elements)) + 1; //Nodes plus subgraphs fit a square grid, calculates square root of next biggest perfect square 

    }
    
    int current_length = 0;
    int row_height = 0; // Height of the current row
    int base_height = 100;
    int longest_x = coordinates[0]; //Longest row overall
    int base_length = 100;

    current_graph.subgraphs = top-down-break visit(current_graph.subgraphs) {
        case g : graph(_,_,_,_):
        {
            if(current_length >= grid_length) {
                current_length = 0;
                longest_x = max(longest_x,coordinates[0]);
                coordinates[0] = toInt(current_graph.attributes["initial_x"]);
                coordinates[1] += (max((row_height - toInt( current_graph.attributes["initial_y"])),0) + base_height);
                row_height = 0;

            }
            current_length += 1;

            subgraph = getLayout(g, coordinates);
            max_x = toInt(subgraph.attributes["max_x"]);
            max_y = toInt(subgraph.attributes["max_y"]); //max_x, max_y is the bottom right point of the subgraph
            coordinates[0] = max_x;
            row_height = max(row_height,max_y); //Track the tallest element, next row will be a distance of that + base height

            insert subgraph;
        }

    }



    current_graph.nodes = top-down-break visit(current_graph.nodes) {
        case updated_node: graphNode(_,_):
        {
            if(current_length >= grid_length) {
                current_length = 0;
                longest_x = max(longest_x,coordinates[0]);
                coordinates[0] = toInt(current_graph.attributes["initial_x"]);
                coordinates[1] += (max((row_height - toInt( current_graph.attributes["initial_y"])),0) + base_height);
                row_height = 0;

            }
            current_length += 1;

            updated_node.attributes["cx"] = "<coordinates[0] + (base_length / 2)>";
            updated_node.attributes["cy"] = "<coordinates[1] + (base_height / 2)>";
            updated_node.attributes["rx"] = "<(base_length / 4) + 10>";
            updated_node.attributes["ry"] = "<(base_height / 4)>";

            coordinates[0] += base_length;


            insert updated_node;
        }

    }

    number = row_height - toInt(current_graph.attributes["initial_y"]);
    println("<number>");
    current_graph.attributes["max_x"] = "<max(coordinates[0] + 50,longest_x+50)>";
    current_graph.attributes["max_y"] = "<coordinates[1] + max((row_height - toInt( current_graph.attributes["initial_y"])),0) + base_height>";
    return current_graph;
}