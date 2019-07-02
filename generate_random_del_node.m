%% 
tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
nodes = tx2kb.bus(:, 1);

nI = 20;
nJ = 200;
cell_delnd = cell(nI, nJ);

for i = 1: nI
    for j = 1: nJ
        ndel = 10*i;
        iunique_removed = randsample(1:size(nodes, 1), ndel);
        nodedel = nodes(iunique_removed, :);
        cell_delnd{i, j} = nodedel;
    end
end

save('delnd.mat', 'nI', 'nJ', 'cell_delnd', 'tx2kb', 'nodes');

%% Generate random nodes deletion based on criteria
clear;
tic;
tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
tx2kb.gen(strcmp(tx2kb.gentype, 'W2'), 9:10) = 0; % Remove wind generators
tx2kb.gen(strcmp(tx2kb.gentype, 'PV'), 9:10) = 0; % Remove wind generators

nI = 20;
nJ = 50;

criteria = {'degree', 'sumMVA', 'sumPMAX', 'baseKV'};

for k = 1: numel(criteria)
    cell_delnd = cell(nI, nJ);
    node_unique_sorted = node_order_by(criteria{k});

    for i = 1: nI
        ndel = 10*i;
        samplebr = random_sample_given_nrow(node_unique_sorted, ndel, nJ);
        for j = 1: size(samplebr, 3)
            cell_delnd{i, j} = samplebr(:, :, j);
        end
    end
    
    switch criteria{k}
        case 'degree'
            cell_delnd_degree = cell_delnd;
            
            if isfile('delnd.mat')
                save('delnd.mat', 'cell_delnd_degree', '-append');
            else
                save('delnd.mat', 'cell_delnd_degree');
            end
            
        case 'sumMVA'
            cell_delnd_sumMVA = cell_delnd;
            
            if isfile('delnd.mat')
                save('delnd.mat', 'cell_delnd_sumMVA', '-append');
            else
                save('delnd.mat', 'cell_delnd_sumMVA');
            end
        case 'sumPMAX'
            cell_delnd_sumPMAX = cell_delnd;
            
            if isfile('delnd.mat')
                save('delnd.mat', 'cell_delnd_sumPMAX', '-append');
            else
                save('delnd.mat', 'cell_delnd_sumPMAX');
            end
        case 'baseKV'
            cell_delnd_baseKV = cell_delnd;
            
            if isfile('delnd.mat')
                save('delnd.mat', 'cell_delnd_baseKV', '-append');
            else
                save('delnd.mat', 'cell_delnd_baseKV');
            end
    end
end