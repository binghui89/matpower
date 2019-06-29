%LAB

%% add MATPOWER paths
addpath( ...
    './lib', ...
    './lib/t', ...
    './data', ...
    './mips/lib', ...
    './mips/lib/t', ...
    './most/lib', ...
    './mostmail/lib/t', ...
    './mptest/lib', ...
    './mptest/lib/t', ...
    '-end' );
% addpath('C:\Program Files\IBM\ILOG\CPLEX_Studio128\cplex\matlab\x64_win64'); % Load cplex solver
addpath('/opt/ohpc/pub/site-licensed/ibm/ILOG/CPLEX_Studio128/cplex/matlab/x86-64_linux');

%% Starts from here.
tx2kb = loadcase('C:\Users\bxl180002\Downloads\RampSolar\ACTIVSg2000\case_ACTIVSg2000.m');
% Some branches have double circuits. 
% tx2kb.branch(i_d2u, :) maps the original branches (with duplications) to 
% unique branches.
% unique_branch(i_u2d, :) inversely maps unique branches into the original
% branches with duplications.
[unique_branch, i_d2u, i_u2d] = unique(tx2kb.branch(:, 1:2), 'rows');

%% Produce the Y matrix for Dorcas
tx2kb_ordered = ext2int(tx2kb);
[Ybus, Yf, Yt] = makeYbus(tx2kb_ordered);
Ybus_full = full(Ybus);
Ybus_full_re = real(Ybus_full);
Ybus_full_im = imag(Ybus_full);

%% Experiment: Solve the OPF model, post-contingency (edge)
define_constants;

% What if we remove one branch and resolve DC-OPF?
niter = 10;
ndel = 10; % Number of delted branches
uniq_br_del = nan(niter, ndel);
for i = 1: niter
    test = tx2kb;
    iunique_removed = randsample(1:length(unique_branch), 10); % The ith unique branch is removed, may include multiple circuits.
    uniq_br_del(i, :) = iunique_removed;
    test.branch(ismember(i_u2d, iunique_removed), :) = []; % Remove branches
    bus_remain = unique(test.branch(:, 1:2));
   
    % Remove isolated buses
    test.bus = test.bus(ismember(test.bus(:, 1), bus_remain), :);

    % Remove isolated gens.
    test.gen = test.gen(ismember(test.gen(:, GEN_BUS), bus_remain), :);
    test.gentype = test.gentype(ismember(test.gen(:, GEN_BUS), bus_remain), :);
    test.genfuel = test.genfuel(ismember(test.gen(:, GEN_BUS), bus_remain), :);
    test.gencost = test.gencost(ismember(test.gen(:, GEN_BUS), bus_remain), :);

    % out.all controls pretty-printing of results, default to -1, 0: nothing.
    % verbose controls amount of progress info to be printed,
    % default to 1, 0 print no progress.
    mpopt = mpoption('out.all', 0, 'verbose', 0); 
%     results = runopf(test, mpopt);
    results = rundcopf(test, mpopt);
    fprintf('Iteration: %g, Alg: %s: %s\n', i, results.raw.output.alg, results.raw.output.message)
end

%% Experiment: Solve one year's load
load_matrix = csvread('C:\Users\bxl180002\Downloads\RampWind\Jubeyer\Texas_2k_load.csv', 1, 1);
load_matrix(:, end) = []; % This column is total load

all_flag = nan(size(load_matrix/24, 1), 1);
all_cost = nan(size(load_matrix/24, 1), 1);
all_load = nan(size(load_matrix/24, 1), 1);
i_loadbus = tx2kb.bus(:, 3)>0;

for d = 1: size(load_matrix/24, 1)
    
    load_day = load_matrix(24*(d-1)+1: 24*d, :);
    [~, imax] = max(sum(load_day, 2));
    
    test = tx2kb;
%     test.gen(:, 10) = 0; % This is Pmin, originally 30% of Pmax, now set to 0 to allow thermal gens to turn off, de-committment model
    test.bus(i_loadbus, 3) = load_day(imax, :)';
    
    mpopt = mpoption('out.all', 0, 'verbose', 0);
    
    results = rundcopf(test, mpopt);
%     results = runduopf(test, mpopt); % DC-OPF de-committment, it's very slow
    
    if ~results.success
        test_relaxed = relax_model(test);
    end

    all_flag(d) = results.success;
    all_cost(d) = results.f;
    all_load(d) = sum(results.bus(:, 3));
    fprintf('Iteration day: %g, Alg: %s, success: %g, Total load: %f, obj: %f\n', d, results.raw.output.alg, results.success, sum(results.bus(:, 3)), results.f);
end
%% Experiment: Random attack on edges/branches
clear;
tx2kb = loadcase('C:\Users\bxl180002\Downloads\RampSolar\ACTIVSg2000\case_ACTIVSg2000.m');
[unique_branch, i_d2u, i_u2d] = unique(tx2kb.branch(:, 1:2), 'rows');

nI = 10; % 10 ~ nI*10 of branches are moved
nJ = 10; % Each number of removed branches are repeated nJ times

% Result containers
status_case = ones(nI, nJ);
cell_delbr  = cell(nI, nJ);
cell_msg    = cell(nI, nJ);
load_shed   = nan(nI, nJ);

for i = 1: nI
    for j = 1: nJ % Just repeat 10 times per attack
        ndel = 10*i;
        iunique_removed = randsample(1:size(unique_branch, 1), ndel); % The ith unique branch is removed, may include multiple circuits.
        branchdel = unique_branch(iunique_removed, :);
        cell_delbr{i, j} = branchdel;
        test = remove_br1(tx2kb, branchdel);
        
        % Display how many isolated islands are left
        cell_islands = extract_islands(test);
        fprintf('Removed: %g, Isolated islands: %g\n', ndel, numel(cell_islands));

        % out.all controls pretty-printing of results, default to -1, 0: nothing.
        % verbose controls amount of progress info to be printed,
        % default to 1, 0 print no progress.
        mpopt = mpoption('out.all', 0, 'verbose', 0);
        
        cell_msg_k  = cell(numel(cell_islands));
        load_shed_k = nan(numel(cell_islands), 1);
        
        for k = 1: numel(cell_islands)
            flag_vg = false; % No VG added at first
            case_k = cell_islands{k};
            results = rundcopf(case_k, mpopt);
            if ~results.success
                [case_k_vg, i_vg] = virtual_gen(case_k); % Add virtual generators
                flag_vg = true;
                case_k_vg.gen(:, 10) = 0; % PMIN = 0;
                results = rundcopf(case_k_vg, mpopt);
            end
            status_case(i, j) = status_case(i, j)*results.success; % So the status will be 1 only and if only all islands can be solved.
            fprintf('Removed: %g, Alg: %s, success: %g, Total load: %f, obj: %f\n', ndel, results.raw.output.alg, results.success, sum(results.bus(:, 3)), results.f);
            if ~results.success
                fprintf('%s\n', results.raw.output.message);
            end
            cell_msg_k{k} = results.raw.output.message;
            if flag_vg
                if ~results.success
                    load_shed_k(k) = nan;
                else
                    load_shed_k(k) = sum(results.gen(i_vg, 2));
                end
            else
                load_shed_k(k) = 0;
            end
        end
        cell_msg{i, j} = cell_msg_k;
        load_shed(i, j) = sum(load_shed_k);
    end
end

%% Experiment: Random attack on nodes/buses
clear;
tx2kb = loadcase('C:\Users\bxl180002\Downloads\RampSolar\ACTIVSg2000\case_ACTIVSg2000.m');
[unique_bus] = unique(tx2kb.bus(:, 1));

nI = 10; % 10 ~ nI*10 of branches are moved
nJ = 10; % Each number of removed branches are repeated nJ times

% Result containers
status_case = ones(nI, nJ);
cell_delbr  = cell(nI, nJ);
cell_msg    = cell(nI, nJ);
load_shed   = nan(nI, nJ);

for i = 1: nI
    for j = 1: nJ % Just repeat 10 times per attack
        ndel = 10*i;
        iunique_removed = randsample(1:length(unique_bus), ndel); % The ith unique branch is removed, may include multiple circuits.
        busdel = unique_bus(iunique_removed);
        cell_delbr{i, j} = busdel;
        test = remove_br1(tx2kb, busdel);
        
        % Display how many isolated islands are left
        cell_islands = extract_islands(test);
        fprintf('Removed: %g, Isolated islands: %g\n', ndel, numel(cell_islands));

        % out.all controls pretty-printing of results, default to -1, 0: nothing.
        % verbose controls amount of progress info to be printed,
        % default to 1, 0 print no progress.
        mpopt = mpoption('out.all', 0, 'verbose', 0);
        
        cell_msg_k  = cell(numel(cell_islands));
        load_shed_k = nan(numel(cell_islands), 1);
        
        for k = 1: numel(cell_islands)
            flag_vg = false; % No VG added at first
            case_k = cell_islands{k};
            results = rundcopf(case_k, mpopt);
            if ~results.success
                [case_k_vg, i_vg] = virtual_gen(case_k); % Add virtual generators
                flag_vg = true;
                case_k_vg.gen(:, 10) = 0; % PMIN = 0;
                results = rundcopf(case_k_vg, mpopt);
            end
            status_case(i, j) = status_case(i, j)*results.success; % So the status will be 1 only and if only all islands can be solved.
            fprintf('Removed: %g, Alg: %s, success: %g, Total load: %f, obj: %f\n', ndel, results.raw.output.alg, results.success, sum(results.bus(:, 3)), results.f);
            if ~results.success
                fprintf('%s\n', results.raw.output.message);
            end
            cell_msg_k{k} = results.raw.output.message;
            if flag_vg
                if ~results.success
                    load_shed_k(k) = nan;
                else
                    load_shed_k(k) = sum(results.gen(i_vg, 2));
                end
            else
                load_shed_k(k) = 0;
            end
        end
        cell_msg{i, j} = cell_msg_k;
        load_shed(i, j) = sum(load_shed_k);
    end
end
