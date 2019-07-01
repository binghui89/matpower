function attack_nd_by_order(order_index)

tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');

if order_index == 1 % by sum of MVA rating
    node_descend = node_order_by('sumMVA');
    matname = 'attack_nd_by_order.sumMVA.mat';
elseif order_index == 2 % by degrees
    node_descend = node_order_by('degree');
    matname = 'attack_nd_by_order.degree.mat';
elseif order_index == 3 % By sum of PMAX
    node_descend = node_order_by('sumPMAX');
    matname = 'attack_nd_by_order.sumPMAX.mat';
elseif order_index == 4 % By kV level
    node_descend = node_order_by('baseKV');
    matname = 'attack_nd_by_order.baseKV.mat';
end

nB = size(node_descend, 1);
array_nremove = 10: 10: 100; % NOTE: WE ONLY CONSIDER 100 NODES REMOVED AT MOST!
nI = length(array_nremove);

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
    nremove = array_nremove(i);
    nodedel = node_descend(1:nremove, :);
        
    parfor d = 1: size(load_matrix, 1)/24

        load_day = load_matrix(24*(d-1)+1: 24*d, :);
        [~, imax] = max(sum(load_day, 2));

        test = tx2kb;
    %     test.gen(:, 10) = 0; % This is Pmin, originally 30% of Pmax, now set to 0 to allow thermal gens to turn off, de-committment model
        test.bus(i_loadbus, 3) = load_day(imax, :)';

        [load_shed_k, results] = run_with_nd_remove(test, nodedel);
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

function [load_shed_k, results] = run_with_nd_remove(mpc, nodedel)
test = remove_nd(mpc, nodedel);
ndel = size(nodedel, 1);

% Display how many isolated islands are left
cell_islands = extract_islands(test);
fprintf('Removed: %g nodes, Isolated islands: %g\n', ndel, numel(cell_islands));

% out.all controls pretty-printing of results, default to -1, 0: nothing.
% verbose controls amount of progress info to be printed,
% default to 1, 0 print no progress.

load_shed_k = nan(numel(cell_islands), 1);

for k = 1: numel(cell_islands)
    case_k = cell_islands{k};
    [case_k_vg, i_vg] = virtual_gen(case_k); % Add virtual generators
    case_k_vg.gen(:, 10) = 0; % PMIN = 0;
    try
        mpopt = mpoption('out.all', 0, 'verbose', 0, 'opf.dc.solver', 'OT');
        results = rundcopf(case_k_vg, mpopt);
    catch
        mpopt = mpoption('out.all', 0, 'verbose', 0, 'opf.dc.solver', 'CPLEX');
%         mpopt = mpoption('out.all', 0, 'verbose', 0, 'opf.dc.solver', 'GUROBI', 'gurobi.timelimit', 300); % If we cannot solve within 5 min, then we cannot solve forever
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
