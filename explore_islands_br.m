%% Random attack

clear;
tic;
load('delbr.mat')
tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
[unique_branch, i_d2u, i_u2d] = unique(tx2kb.branch(:, 1:2), 'rows');

load_matrix = csvread('./ACTIVSg2000/Jubeyer/Texas_2k_load.csv', 1, 1);
load_matrix(:, end) = []; % This column is total load
i_loadbus = tx2kb.bus(:, 3)>0;
nd = size(load_matrix,1);


nI = 20;
nJ = 200;
nislands_random = nan(nI, nJ);
lolp_random     = nan(nI, nJ);

for i = 1: nI
    parfor j = 1: nJ % Just repeat 10 times per attack
        if i <= size(cell_delbr, 1)
            branchdel = cell_delbr{i, j};
        else % Generate on fly
            ndel = 10*i;
            iunique_removed = randsample(1:size(unique_branch, 1), ndel);
            branchdel = unique_branch(iunique_removed, :);
        end
        
        loss_of_load = nan(nd, 1);

        for d = 1: nd
            
            test = tx2kb;
            test.bus(i_loadbus, 3) = load_matrix(d, :)';
            test = remove_br1(test, branchdel);
            loss_of_load(d) = lolp_static(test);

        end
        cell_islands = extract_islands(test);
        nislands_random(i, j) = numel(cell_islands);
        lolp_random(i, j) = sum(loss_of_load)/nd;

    end
    toc;
end

if isfile('explore_islands_br.mat')
    save('explore_islands_br.mat', 'nislands_random', 'lolp_random', '-append');
else
    save('explore_islands_br.mat', 'nislands_random', 'lolp_random');
end

%% MVA ratings
clear;
tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
[edge_unique, i_d2u, i_u2d] = unique(tx2kb.branch(:, 1:2), 'rows');

load_matrix = csvread('./ACTIVSg2000/Jubeyer/Texas_2k_load.csv', 1, 1);
load_matrix(:, end) = []; % This column is total load
i_loadbus = tx2kb.bus(:, 3)>0;
nd = size(load_matrix,1);

mva_rating = nan(size(edge_unique, 1), 1);
for i = 1: size(edge_unique, 1)
    bus_from = edge_unique(i, 1);
    bus_to   = edge_unique(i, 2);
    i_rows = (tx2kb.branch(:, 1) == bus_from) & (tx2kb.branch(:, 2) == bus_to);
    mva_rating(i) = sum(tx2kb.branch(i_rows, 6)); % Column 6 is MVA ratings
end
edge_unique = [edge_unique, mva_rating];
edge_unique_sorted = sortrows(edge_unique, 3, 'descend'); 
edge_descend = edge_unique_sorted(:, 1:2); % This is the order of removed branches

nedge_remove = 10: 10: 200;
nI = length(nedge_remove);
nislands_mva_rating = nan(nI, 1);
lolp_mva_rating = nan(nI, 1);

for i = 1: nI
    ne_del = nedge_remove(i);
    branchdel = edge_descend(1: ne_del, :);
    
    parfor d = 1: nd

        test = tx2kb;
        test.bus(i_loadbus, 3) = load_matrix(d, :)';
        test = remove_br1(test, branchdel);
        loss_of_load(d) = lolp_static(test);

    end
    lolp_mva_rating(i) = sum(loss_of_load)/nd;


    test = remove_br1(tx2kb, branchdel);
    ndel = size(branchdel, 1);

    % Display how many isolated islands are left
    cell_islands = extract_islands(test);
    nislands_mva_rating(i) = numel(cell_islands);
end

if isfile('explore_islands_br.mat')
    save('explore_islands_br.mat', 'nislands_mva_rating', 'lolp_mva_rating', '-append');
else
    save('explore_islands_br.mat', 'nislands_mva_rating', 'lolp_mva_rating');
end

% Sum of degrees of from-bus and to-bus
tic;
clear;
tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
tx2kb_br_ordered = tx2kb;

load_matrix = csvread('./ACTIVSg2000/Jubeyer/Texas_2k_load.csv', 1, 1);
load_matrix(:, end) = []; % This column is total load
i_loadbus = tx2kb.bus(:, 3)>0;
nd = size(load_matrix,1);

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
edge_degree_sum = zeros(nedge, 1);
for i = 1: nedge
    bus_from = int2str(edge_unique(i, 1));
    bus_to   = int2str(edge_unique(i, 2));
    edge_degree_sum(i) = G.Nodes.Degree(strcmp(G.Nodes.Name, bus_from)) + G.Nodes.Degree(strcmp(G.Nodes.Name, bus_to));
end
edge_unique = [edge_unique, edge_degree_sum];
edge_unique_sorted = sortrows(edge_unique, 3, 'descend'); % Sort by degree sum
edge_descend = edge_unique_sorted(:, 1:2); % This is the order of removed branches

nedge_remove = 10: 10: 200;
nI = length(nedge_remove);
nislands_sum_degree = nan(nI, 1);
lolp_sum_degree = nan(nI, 1);

for i = 1: nI
    ne_del = nedge_remove(i);
    branchdel = edge_descend(1: ne_del, :);
    
    parfor d = 1: nd

        test = tx2kb;
        test.bus(i_loadbus, 3) = load_matrix(d, :)';
        test = remove_br1(test, branchdel);
        loss_of_load(d) = lolp_static(test);

    end
    lolp_sum_degree(i) = sum(loss_of_load)/nd;


    test = remove_br1(tx2kb, branchdel);
    ndel = size(branchdel, 1);

    % Display how many isolated islands are left
    cell_islands = extract_islands(test);
    nislands_sum_degree(i) = numel(cell_islands);
end

if isfile('explore_islands_br.mat')
    save('explore_islands_br.mat', 'nislands_sum_degree', 'lolp_sum_degree', '-append');
else
    save('explore_islands_br.mat', 'nislands_sum_degree', 'lolp_sum_degree');
end
toc;