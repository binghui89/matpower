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

criteria = {'random', 'sumdegree', 'MVA'};
ncr = numel(criteria);

for c = 1: ncr
    
    cr = criteria{c};
    
    switch cr
        case 'sumdegree'
            load('delbr.mat', 'cell_delbr_sumdegree');
            cell_delbr = cell_delbr_sumdegree;
        case 'MVA'
            load('delbr.mat', 'cell_delbr_MVA');
            cell_delbr = cell_delbr_MVA;
        case 'random'
            load('delbr.mat', 'cell_delbr');
    end

    nislands = nan(nI, nJ);
    lolp     = nan(nI, nd, nJ);

    for i = 1: nI
        for j = 1: nJ
            branchdel = cell_delbr{i, j};

            if isempty(branchdel)
                continue;
            end

            parfor d = 1: nd

                load_day = load_matrix(24*(d-1)+1: 24*d, :);
                [~, imax] = max(sum(load_day, 2));

                test = tx2kb;
                test.bus(i_loadbus, 3) = load_day(imax, :)';
                test = remove_br1(test, branchdel);
    %             loss_of_load(d) = lolp_static(test);
                lolp(i, d, j) = lolp_static(test);

            end
            test = remove_br1(tx2kb, branchdel);
            cell_islands = extract_islands(test);
            nislands(i, j) = numel(cell_islands);
    %         lolp_random(i, j) = sum(loss_of_load)/nd;

        end
        toc;
    end
    
    switch cr
        case 'sumdegree'
            nislands_sumdegree = nislands;
            lolp_sumdegree = lolp;

            if isfile('explore_islands_br.mat')
                save('explore_islands_br.mat', 'nislands_sumdegree', 'lolp_sumdegree', '-append');
            else
                save('explore_islands_br.mat', 'nislands_sumdegree', 'lolp_sumdegree');
            end

        case 'MVA'
            nislands_MVA = nislands;
            lolp_MVA = lolp;
            
            if isfile('explore_islands_br.mat')
                save('explore_islands_br.mat', 'nislands_MVA', 'lolp_MVA', '-append');
            else
                save('explore_islands_br.mat', 'nislands_MVA', 'lolp_MVA');
            end
        case 'random'
            nislands_random = nislands;
            lolp_random = lolp;
            
            if isfile('explore_islands_br.mat')
                save('explore_islands_br.mat', 'nislands_random', 'lolp_random', '-append');
            else
                save('explore_islands_br.mat', 'nislands_random', 'lolp_random');
            end
    end

end
