%% New iteration-based approach
clear;
tic;
tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
tx2kb.gen(strcmp(tx2kb.gentype, 'W2'), 9:10) = 0; % Remove wind generators
tx2kb.gen(strcmp(tx2kb.gentype, 'PV'), 9:10) = 0; % Remove wind generators


load_matrix = csvread('./ACTIVSg2000/Jubeyer/Texas_2k_load.csv', 1, 1);
load_matrix(:, end) = []; % This column is total load
i_loadbus = tx2kb.bus(:, 3)>0;

nd = size(load_matrix,1)/24; % We only look at peak hours per day
nI = 20;
nJ = 50;

criteria = {'random', 'degree', 'sumMVA', 'sumPMAX', 'baseKV'};
ncr = numel(criteria);

for c = 1: ncr
    
    cr = criteria{c};
    
    switch cr
        case 'degree'
            load('delnd.mat', 'cell_delnd_degree');
            cell_delnd = cell_delnd_degree;
        case 'sumMVA'
            load('delnd.mat', 'cell_delnd_sumMVA');
            cell_delnd = cell_delnd_sumMVA;
        case 'sumPMAX'
            load('delnd.mat', 'cell_delnd_sumPMAX');
            cell_delnd = cell_delnd_sumPMAX;
        case 'baseKV'
            load('delnd.mat', 'cell_delnd_baseKV');
            cell_delnd = cell_delnd_baseKV;
        case 'random'
            load('delnd.mat', 'cell_delnd');
    end

    nislands = nan(nI, nJ);
    lolp     = nan(nI, nd, nJ);

    for i = 1: nI
        for j = 1: nJ
            nodedel = cell_delnd{i, j};

            if isempty(nodedel)
                continue;
            end

            parfor d = 1: nd

                load_day = load_matrix(24*(d-1)+1: 24*d, :);
                [~, imax] = max(sum(load_day, 2));

                test = tx2kb;
                test.bus(i_loadbus, 3) = load_day(imax, :)';
                test = remove_nd(test, nodedel);
    %             loss_of_load(d) = lolp_static(test);
                lolp(i, d, j) = lolp_static(test);

            end
            test = remove_nd(tx2kb, nodedel);
            cell_islands = extract_islands(test);
            nislands(i, j) = numel(cell_islands);
    %         lolp_random(i, j) = sum(loss_of_load)/nd;

        end
        toc;
    end
    
    switch cr
        case 'degree'
            nislands_degree = nislands;
            lolp_degree = lolp;

            if isfile('explore_islands_nd.mat')
                save('explore_islands_nd.mat', 'nislands_degree', 'lolp_degree', '-append');
            else
                save('explore_islands_nd.mat', 'nislands_degree', 'lolp_degree');
            end

        case 'sumMVA'
            nislands_sumMVA = nislands;
            lolp_sumMVA = lolp;
            
            if isfile('explore_islands_nd.mat')
                save('explore_islands_nd.mat', 'nislands_sumMVA', 'lolp_sumMVA', '-append');
            else
                save('explore_islands_nd.mat', 'nislands_sumMVA', 'lolp_sumMVA');
            end
        case 'sumPMAX'
            nislands_sumPMAX = nislands;
            lolp_sumPMAX = lolp;
            
            if isfile('explore_islands_nd.mat')
                save('explore_islands_nd.mat', 'nislands_sumPMAX', 'lolp_sumPMAX', '-append');
            else
                save('explore_islands_nd.mat', 'nislands_sumPMAX', 'lolp_sumPMAX');
            end
        case 'baseKV'
            nislands_baseKV = nislands;
            lolp_baseKV = lolp;
            
            if isfile('explore_islands_nd.mat')
                save('explore_islands_nd.mat', 'nislands_baseKV', 'lolp_baseKV', '-append');
            else
                save('explore_islands_nd.mat', 'nislands_baseKV', 'lolp_baseKV');
            end
        case 'random'
            nislands_random = nislands;
            lolp_random = lolp;
            
            if isfile('explore_islands_nd.mat')
                save('explore_islands_nd.mat', 'nislands_random', 'lolp_random', '-append');
            else
                save('explore_islands_nd.mat', 'nislands_random', 'lolp_random');
            end
    end

end
