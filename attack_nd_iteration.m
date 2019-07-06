function attack_nd_iteration(rank_base)
% rank_base: random, degree, sumMVA, sumPMAX, baseKV

tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
tx2kb.gen(strcmp(tx2kb.gentype, 'W2'), 9:10) = 0; % Remove wind generators
tx2kb.gen(strcmp(tx2kb.gentype, 'PV'), 9:10) = 0; % Remove wind generators

switch rank_base
    case 'random'
        load('delnd.mat', 'cell_delnd');
        cell_del = cell_delnd;
    case 'degree'
        load('delnd.mat', 'cell_delnd_degree');
        cell_del = cell_delnd_degree;
    case 'sumMVA'
        load('delnd.mat', 'cell_delnd_sumMVA');
        cell_del = cell_delnd_sumMVA;
    case 'sumPMAX'
        load('delnd.mat', 'cell_delnd_sumPMAX');
        cell_del = cell_delnd_sumPMAX;
    case 'baseKV'
        load('delnd.mat', 'cell_delnd_baseKV');
        cell_del = cell_delnd_baseKV;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nI = 10;
nJ = 50;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tx2kb.gencost(:, 5) = 0; % Cost functions are forced to be linear to avoid non-convex situation. We don't care about costs so this should be OK.

load_matrix = csvread('./ACTIVSg2000/Jubeyer/Texas_2k_load.csv', 1, 1);
load_matrix(:, end) = []; % This column is total load
i_loadbus = tx2kb.bus(:, 3)>0;

nd = size(load_matrix, 1)/24;

load_total   = nan(nI, nd, nJ);
load_shed    = nan(nI, nd, nJ);
lolp         = nan(nI, nd, nJ);
load_shed_c  = cell(nI, nd, nJ);

tic;
for i = 1: 1: nI
    for j = 1: nJ
        fprintf('i: %g, j: %g\n', i, j);
        del_this = cell_del{i, j};
        
        if isempty(del_this) % This cell is empty, no ranking
            continue;
        end
        
        for d = 1: nd

            load_day = load_matrix(24*(d-1)+1: 24*d, :);
            [~, imax] = max(sum(load_day, 2));

            test = tx2kb;
            test.bus(i_loadbus, 3) = load_day(imax, :)';

            [load_shed_k, lolp_k, ~] = run_with_nd_remove(test, del_this);
            load_shed_c{i, d, j} = load_shed_k;
            load_total(i, d, j) = sum(load_day(imax, :));
            load_shed(i, d, j)  = sum(load_shed_k);
            lolp(i, d, j) = any(lolp_k);
            fprintf('d = %g Done, time: %.4f\n', d, toc);
        end
    end
end

switch rank_base
    case 'random'
        load_total_random  = load_total;
        load_shed_random   = load_shed;
        lolp_random        = lolp;
        load_shed_c_random = load_shed_c;
        if isfile('attack_nd_iteration.mat')
            save('attack_nd_iteration.mat', 'load_total_random', 'load_shed_random', 'lolp_random', 'load_shed_c_random', '-append');
        else
            save('attack_nd_iteration.mat', 'load_total_random', 'load_shed_random', 'lolp_random', 'load_shed_c_random');
        end
    case 'degree'
        load_total_degree  = load_total;
        load_shed_degree   = load_shed;
        lolp_degree        = lolp;
        load_shed_c_degree = load_shed_c;
        if isfile('attack_nd_iteration.mat')
            save('attack_nd_iteration.mat', 'load_total_degree', 'load_shed_degree', 'lolp_degree', 'load_shed_c_degree', '-append');
        else
            save('attack_nd_iteration.mat', 'load_total_degree', 'load_shed_degree', 'lolp_degree', 'load_shed_c_degree');
        end
    case 'sumMVA'
        load_total_sumMVA  = load_total;
        load_shed_sumMVA   = load_shed;
        lolp_sumMVA        = lolp;
        load_shed_c_sumMVA = load_shed_c;
        if isfile('attack_nd_iteration.mat')
            save('attack_nd_iteration.mat', 'load_total_sumMVA', 'load_shed_sumMVA', 'lolp_sumMVA', 'load_shed_c_sumMVA', '-append');
        else
            save('attack_nd_iteration.mat', 'load_total_sumMVA', 'load_shed_sumMVA', 'lolp_sumMVA', 'load_shed_c_sumMVA');
        end
    case 'sumPMAX'
        load_total_sumPMAX  = load_total;
        load_shed_sumPMAX   = load_shed;
        lolp_sumPMAX        = lolp;
        load_shed_c_sumPMAX = load_shed_c;
        if isfile('attack_nd_iteration.mat')
            save('attack_nd_iteration.mat', 'load_total_sumPMAX', 'load_shed_sumPMAX', 'lolp_sumPMAX', 'load_shed_c_sumPMAX', '-append');
        else
            save('attack_nd_iteration.mat', 'load_total_sumPMAX', 'load_shed_sumPMAX', 'lolp_sumPMAX', 'load_shed_c_sumPMAX');
        end
    case 'baseKV'
        load_total_baseKV  = load_total;
        load_shed_baseKV   = load_shed;
        lolp_baseKV        = lolp;
        load_shed_c_baseKV = load_shed_c;
        if isfile('attack_nd_iteration.mat')
            save('attack_nd_iteration.mat', 'load_total_baseKV', 'load_shed_baseKV', 'lolp_baseKV', 'load_shed_c_baseKV', '-append');
        else
            save('attack_nd_iteration.mat', 'load_total_baseKV', 'load_shed_baseKV', 'lolp_baseKV', 'load_shed_c_baseKV');
        end
end
 

end

function [load_shed_k, lolp_k, results] = run_with_nd_remove(mpc, nodedel)
tol = 1E-3;
test = remove_nd(mpc, nodedel);
ndel = size(nodedel, 1);

% Display how many isolated islands are left
cell_islands = extract_islands(test);

% out.all controls pretty-printing of results, default to -1, 0: nothing.
% verbose controls amount of progress info to be printed,
% default to 1, 0 print no progress.

load_shed_k = nan(numel(cell_islands), 1);
lolp_k      = nan(numel(cell_islands), 1);

for k = 1: numel(cell_islands)
    case_k = cell_islands{k};
    sum_load_k = sum(case_k.bus(:, 3));
    sum_gen_k  = sum(case_k.gen(:, 9));
    if (sum_load_k <= tol)
        load_shed_k(k) = 0;
        lolp_k(k) = false;
    elseif (sum_gen_k <= tol) && (sum_load_k >= tol) % No generating capacity
        load_shed_k(k) = sum_load_k; % All load is shedded
        lolp_k(k) = true;
        continue;
    end
    [case_k_vg, i_vg] = virtual_gen(case_k); % Add virtual generators
    case_k_vg.gen(:, 10) = 0; % PMIN = 0;
    try
        mpopt = mpoption('out.all', 0, 'verbose', 0, 'opf.dc.solver', 'GUROBI', 'gurobi.timelimit', 60); % If we cannot solve within 1 min, then we cannot solve forever
        results = rundcopf(case_k_vg, mpopt);
    catch
        mpopt = mpoption('out.all', 0, 'verbose', 0, 'opf.dc.solver', 'CPLEX');
        results = rundcopf(case_k_vg, mpopt);
    end

    if ~results.success
        try
            mpopt = mpoption('out.all', 0, 'verbose', 0, 'opf.dc.solver', 'OT');
            results = rundcopf(case_k_vg, mpopt);
            fprintf('Repeat using linprog\n');
        catch
            mpopt = mpoption('out.all', 0, 'verbose', 0, 'opf.dc.solver', 'CPLEX');
            results = rundcopf(case_k_vg, mpopt);
        end
    end

    if ~results.success
        try
            raw_message = results.raw.output.message;
            fprintf('%s\n', raw_message);
        catch
        end
        load_shed_k(k) = nan;
        lolp_k(k) = nan;
    else
        load_shed_k(k) = sum(results.gen(i_vg, 2));
        lolp_k(k) = (load_shed_k(k) >= tol);
    end

    fprintf('Removed: %g, Alg: %s, success: %g, Total load: %.2f, Total shed load: %.2f, obj: %.2f\n', ndel, results.raw.output.alg, results.success, sum(results.bus(:, 3)), load_shed_k(k), results.f);
end

end
