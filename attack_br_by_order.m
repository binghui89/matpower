function attack_br_by_order(order_index)
% order_index: 1 = by MVA rating, 2 = by sum of degrees

tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');

if order_index == 1 % by MVA rating
    edge_descend = edge_order_by_mva_rating();
    matname = 'attack_br_by_order.mva_rating.mat';
elseif order_index == 2 % by sum of degrees
    edge_descend = edge_order_by_degree_sum();
    matname = 'attack_br_by_order.degree_sum.mat';
end

nB = size(edge_descend, 1);
nedge_remove = 1: 10: 200;
nI = length(nedge_remove);

tic;
tx2kb.gencost(:, 5) = 0; % Cost functions are forced to be linear to avoid non-convex situation. We don't care about costs so this should be OK.
% Some how change the cost function into linear lead to (1) unboundness and (2) linprog error "-2-4", before we figure out why, we should use qp.
% [unique_branch, i_d2u, i_u2d] = unique(tx2kb.branch(:, 1:2), 'rows');

load_matrix = csvread('./ACTIVSg2000/Jubeyer/Texas_2k_load.csv', 1, 1);
load_matrix(:, end) = []; % This column is total load
i_loadbus = tx2kb.bus(:, 3)>0;

% Result containers
% status_case = ones(nI, nJ);
% cell_msg    = cell(nI, nJ);
load_total   = nan(nI, size(load_matrix, 1)/24);
load_shed    = nan(nI, size(load_matrix, 1)/24);
% cell_results = cell(nI, nJ_host, size(load_matrix, 1)/24);

for i = 1: nI
    ne_del = nedge_remove(i);
    branchdel = edge_descend(1:ne_del, :);
        
    parfor d = 1: size(load_matrix, 1)/24

        load_day = load_matrix(24*(d-1)+1: 24*d, :);
        [~, imax] = max(sum(load_day, 2));

        test = tx2kb;
    %     test.gen(:, 10) = 0; % This is Pmin, originally 30% of Pmax, now set to 0 to allow thermal gens to turn off, de-committment model
        test.bus(i_loadbus, 3) = load_day(imax, :)';

        [load_shed_k, results] = run_with_br_remove(test, branchdel);
        load_total(i, d) = sum(load_day(imax, :));
        load_shed(i, d)  = sum(load_shed_k);
    end

end

toc;

lolp = mean(...
    sum((~isnan(load_shed)) & (load_shed>1E-3), 2)./sum(~isnan(load_shed), 2), 2 ...
    ); % Loss-of-load probability
save(matname);
end

function edge_descend = edge_order_by_mva_rating()
tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
[edge_unique, i_d2u, i_u2d] = unique(tx2kb.branch(:, 1:2), 'rows');


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

end

function edge_descend = edge_order_by_degree_sum()
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
edge_degree_sum = zeros(nedge, 1);
for i = 1: nedge
    bus_from = int2str(edge_unique(i, 1));
    bus_to   = int2str(edge_unique(i, 2));
    edge_degree_sum(i) = G.Nodes.Degree(strcmp(G.Nodes.Name, bus_from)) + G.Nodes.Degree(strcmp(G.Nodes.Name, bus_to));
end
edge_unique = [edge_unique, edge_degree_sum];
edge_unique_sorted = sortrows(edge_unique, 3, 'descend'); % Sort by degree sum
edge_descend = edge_unique_sorted(:, 1:2); % This is the order of removed branches
end

function [load_shed_k, results] = run_with_br_remove(mpc, branchdel)
test = remove_br1(mpc, branchdel);
ndel = size(branchdel, 1);

% Display how many isolated islands are left
cell_islands = extract_islands(test);
fprintf('Removed: %g, Isolated islands: %g\n', ndel, numel(cell_islands));

% out.all controls pretty-printing of results, default to -1, 0: nothing.
% verbose controls amount of progress info to be printed,
% default to 1, 0 print no progress.
mpopt = mpoption('out.all', 0, 'verbose', 0, 'opf.dc.solver', 'OT');

load_shed_k = nan(numel(cell_islands), 1);

for k = 1: numel(cell_islands)
    case_k = cell_islands{k};
    [case_k_vg, i_vg] = virtual_gen(case_k); % Add virtual generators
    case_k_vg.gen(:, 10) = 0; % PMIN = 0;
    try
        results = rundcopf(case_k_vg, mpopt);
    catch
        mpopt = mpoption('out.all', 0, 'verbose', 0, 'opf.dc.solver', 'CPLEX');
        results = rundcopf(case_k_vg, mpopt);
    end
    fprintf('Removed: %g, Alg: %s, success: %g, Total load: %f, obj: %f\n', ndel, results.raw.output.alg, results.success, sum(results.bus(:, 3)), results.f);
    if ~results.success
        fprintf('%s\n', results.raw.output.message);
        load_shed_k(k) = nan;
    else
        load_shed_k(k) = sum(results.gen(i_vg, 2));
    end
end

end
