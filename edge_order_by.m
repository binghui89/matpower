function edge_descend = edge_order_by(attr)
% attr: 'sumdegree', 'sumKV', 'sumPMAX', 'MVA'
% Return: An array of nodes ordered by attr (nx3) array, the last column is
% ranking criteria
% 'sumdegree': Sum of degree
% 'MVA':  branch MVA ratings
% 'sumKV': Sum of base KV values
% 'sumPMAX': Sum of gen PMAX

tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
tx2kb.gen(strcmp(tx2kb.gentype, 'W2'), 9:10) = 0; % Remove wind generators
tx2kb.gen(strcmp(tx2kb.gentype, 'PV'), 9:10) = 0; % Remove wind generators

tx2kb_br_ordered = tx2kb;
for i = 1: size(tx2kb_br_ordered.branch, 1)
    bus_from = tx2kb_br_ordered.branch(i, 1);
    bus_to   = tx2kb_br_ordered.branch(i, 2);
    if bus_from > bus_to
        tx2kb_br_ordered.branch(i, 1) = bus_to;
        tx2kb_br_ordered.branch(i, 2) = bus_from;
    end
end
[edge_unique, i_d2u, i_u2d] = unique(tx2kb_br_ordered.branch(:, 1:2), 'rows');
nedge = size(edge_unique, 1);
s = cell(nedge, 1);
t = cell(nedge, 1);
for i = 1: nedge
    s{i} = int2str(edge_unique(i, 1));
    t{i} = int2str(edge_unique(i, 2));
end

G = graph(s, t);
G.Nodes.Degree = degree(G);


array_edges = [nan(size(edge_unique)), nan(size(edge_unique, 1), 4)];
for i = 1: size(G.Edges, 1) % G.Edges should include the same number of edges as array_edges does
    strbusf = G.Edges{i, 'EndNodes'}{1};
    strbust = G.Edges{i, 'EndNodes'}{2};
    busf = str2double(strbusf);
    bust = str2double(strbust);
    sumdegree = G.Nodes.Degree(strcmp(G.Nodes.Name, strbusf)) + G.Nodes.Degree(strcmp(G.Nodes.Name, strbust));
    i_selected_br = ((tx2kb.branch(:, 1)==busf) & (tx2kb.branch(:, 2)==bust)) | ((tx2kb.branch(:, 1)==bust) & (tx2kb.branch(:, 2)==busf));
    MVA = sum(tx2kb.branch(i_selected_br, 6));
    kVf = tx2kb.bus(tx2kb.bus == busf, 10);
    kVt = tx2kb.bus(tx2kb.bus == bust, 10);
    PMAXf = sum(tx2kb.gen(tx2kb.gen(:, 1)==busf, 9));
    PMAXt = sum(tx2kb.gen(tx2kb.gen(:, 1)==bust, 9));
    
    array_edges(i, 1) = busf;
    array_edges(i, 2) = bust;
    array_edges(i, 3) = sumdegree;
    array_edges(i, 4) = MVA;
    array_edges(i, 5) = kVf + kVt;
    array_edges(i, 6) = PMAXf + PMAXt;
end

switch attr
    case 'sumdegree' 
        iwhat = 3; % iwhat is the number of column of the selected attr in array_edges
    case 'MVA'
        iwhat = 4;
    case 'sumKV'
        iwhat = 5;
    case 'sumPMAX'
        iwhat = 6;
end


array_edges_sorted = sortrows(array_edges, iwhat, 'descend');

edge_descend = array_edges_sorted(:, [1:2, iwhat]); % The ranking criteria is included in the output
end