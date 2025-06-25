module DataTypes

data GraphNode = graphNode(str name, map[str,str] attributes);
data Graph = graph(str name, list[GraphNode] nodes, list[Graph] subgraphs, map[str,str] attributes);
data Edge = edge(GraphNode node_1, GraphNode node_2, map[str,str] attributes);