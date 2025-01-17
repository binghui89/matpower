function attack_br(nbatch)
% nbatch = 1, 2, 3, 4, which corresponds to number of removed edges from 10
% to50, 60:100, 110:150 and 160 to 200
tic;
load('delbr.mat');
tx2kb.gencost(:, 5) = 0; % Cost functions are forced to be linear to avoid non-convex situation. We don't care about costs so this should be OK.
% Some how change the cost function into linear lead to (1) unboundness and (2) linprog error "-2-4", before we figure out why, we should use qp.
% [unique_branch, i_d2u, i_u2d] = unique(tx2kb.branch(:, 1:2), 'rows');

load_matrix = csvread('./ACTIVSg2000/Jubeyer/Texas_2k_load.csv', 1, 1);
load_matrix(:, end) = []; % This column is total load
i_loadbus = tx2kb.bus(:, 3)>0;

nJ = 50;

% nI = 10; % 10 ~ nI*10 of branches are moved
% nJ = nJ/nhost; % Each node are assigned 1/3 of total tasks
% cell_delbr_host = cell_delbr(:, (host-1)*nJ+1: host*nJ);

% Result containers
% status_case = ones(nI, nJ);
% cell_msg    = cell(nI, nJ);

Ibatch = (nbatch-1)*5+1: nbatch*5;
nI = numel(Ibatch);
load_total   = nan(nI, size(load_matrix, 1)/24, nJ);
load_shed    = nan(nI, size(load_matrix, 1)/24, nJ);
% cell_results = cell(nI, nJ_host, size(load_matrix, 1)/24);

for i = Ibatch
    for j = 1: nJ 
%         ndel = 10*i;
%         iunique_removed = randsample(1:size(unique_branch, 1), ndel); % The ith unique branch is removed, may include multiple circuits.
%         branchdel = unique_branch(iunique_removed, :);
        branchdel = cell_delbr{i, j};
%         cell_delbr{i, j} = branchdel;
        
        parfor d = 1: size(load_matrix, 1)/24

            load_day = load_matrix(24*(d-1)+1: 24*d, :);
            [~, imax] = max(sum(load_day, 2));

            test = tx2kb;
        %     test.gen(:, 10) = 0; % This is Pmin, originally 30% of Pmax, now set to 0 to allow thermal gens to turn off, de-committment model
            test.bus(i_loadbus, 3) = load_day(imax, :)';
            
            [load_shed_k, results] = run_with_br_remove(test, branchdel);
%             cell_results{i, j, d} = results;
            load_total(i, d, j) = sum(load_day(imax, :));
            load_shed(i, d, j)  = sum(load_shed_k);

        end

    end
end

toc;

lolp = mean(...
    sum((~isnan(load_shed)) & (load_shed>1E-3), 2)./sum(~isnan(load_shed), 2), 3 ...
    ); % Loss-of-load probability
savename = strcat('attack_br_by_order.random', int2str(nbatch), '.mat');
save(savename);
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

% function [load_shed_k, results] = run_with_br_remove(mpc, branchdel)
% test = remove_br1(mpc, branchdel);
% ndel = size(branchdel, 1);
% 
% % Display how many isolated islands are left
% cell_islands = extract_islands(test);
% fprintf('Removed: %g, Isolated islands: %g\n', ndel, numel(cell_islands));
% 
% % out.all controls pretty-printing of results, default to -1, 0: nothing.
% % verbose controls amount of progress info to be printed,
% % default to 1, 0 print no progress.
% mpopt = mpoption('out.all', 0, 'verbose', 0);
% 
% % cell_msg_k  = cell(numel(cell_islands));
% load_shed_k = nan(numel(cell_islands), 1);
% 
% for k = 1: numel(cell_islands)
%     flag_vg = false; % No VG added at first
%     case_k = cell_islands{k};
%     results = rundcopf(case_k, mpopt);
%     if ~results.success
%         [case_k_vg, i_vg] = virtual_gen(case_k); % Add virtual generators
%         flag_vg = true;
%         case_k_vg.gen(:, 10) = 0; % PMIN = 0;
%         results = rundcopf(case_k_vg, mpopt);
%     end
%     fprintf('Removed: %g, Alg: %s, success: %g, Total load: %f, obj: %f\n', ndel, results.raw.output.alg, results.success, sum(results.bus(:, 3)), results.f);
%     if ~results.success
%         fprintf('%s\n', results.raw.output.message);
%     end
% %     cell_msg_k{k} = results.raw.output.message;
%     if flag_vg
%         if ~results.success
%             load_shed_k(k) = nan;
%         else
%             load_shed_k(k) = sum(results.gen(i_vg, 2));
%         end
%     else
%         load_shed_k(k) = 0;
%     end
% end
% 
% end