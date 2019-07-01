function node_descend = node_order_by(attr)
% attr: 'degree', 'baseKV', 'sumPMAX', 'sumMVA'
tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
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

array_nodes = nan(size(G.Nodes, 1), 5);
for i = 1: size(G.Nodes, 1)
    strnode = G.Nodes{i, 'Name'}{1};
    node = str2num(strnode);
    baseKV  = tx2kb.bus(tx2kb.bus(:, 1)==node, 10);
    sumPMAX = sum(tx2kb.gen(tx2kb.gen(:, 1)==node, 9));
    sumMVA  = sum(tx2kb.branch((tx2kb.branch(:, 1)==node) | (tx2kb.branch(:, 2)==node), 6));
    G.Nodes{i, 'baseKV'}  = baseKV;
    G.Nodes{i, 'sumPMAX'} = sumPMAX;
    G.Nodes{i, 'sumMVA'}  = sumMVA;
    
    array_nodes(i, 1) = node;
    array_nodes(i, 2) = G.Nodes.Degree(i);
    array_nodes(i, 3) = baseKV;
    array_nodes(i, 4) = sumPMAX;
    array_nodes(i, 5) = sumMVA;
end

switch attr
    case 'degree'
        iwhat = 2;
    case 'baseKV'
        iwhat = 3;
    case 'sumPMAX'
        iwhat = 4;
    case 'sumMVA'
        iwhat = 5;
end

array_nodes_sorted = sortrows(array_nodes, iwhat, 'descend');

node_descend = array_nodes_sorted(:, 1);
end