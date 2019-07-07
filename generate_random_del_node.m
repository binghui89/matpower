%%
clear;
tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
nodes = tx2kb.bus(:, 1);

nI = 10;
nJ = 50;
cell_delnd = cell(nI, nJ);

for j = 1: nJ
    ndel = 10*nI;
    iunique_removed = randsample(1:size(nodes, 1), ndel);
    nodedel = nodes(iunique_removed, :);
    for i = 1: nI
        cell_delnd{i, j} = nodedel(1: i*10, :);
    end
end

save('delnd.mat', 'nI', 'nJ', 'cell_delnd', 'nodes');

%% Generate random nodes deletion based on criteria
clear;
tic;
tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
tx2kb.gen(strcmp(tx2kb.gentype, 'W2'), 9:10) = 0; % Remove wind generators
tx2kb.gen(strcmp(tx2kb.gentype, 'PV'), 9:10) = 0; % Remove wind generators

nI = 10;
nJ = 50;

criteria = {'degree', 'sumMVA', 'sumPMAX', 'baseKV'};

for k = 1: numel(criteria)
    cell_delnd = cell(nI, nJ);
    node_unique_sorted = node_order_by(criteria{k});
    
    ndel = 10*nI;
    samplend = random_sample_given_nrow(node_unique_sorted, ndel, nJ);

    for j = 1: size(samplend, 3)
        for i = 1: nI
            cell_delnd{i, j} = samplend(1: i*10, 1, j);
        end
    end

    
    switch criteria{k}
        case 'degree'
            cell_delnd_degree = cell_delnd;

            write_folder('C:\Users\bxl180002\git\matpower\Dorcas\node\degree', samplend);
            if isfile('delnd.mat')
                save('delnd.mat', 'cell_delnd_degree', '-append');
            else
                save('delnd.mat', 'cell_delnd_degree');
            end
            
        case 'sumMVA'
            cell_delnd_sumMVA = cell_delnd;

            write_folder('C:\Users\bxl180002\git\matpower\Dorcas\node\sumMVA', samplend);
            if isfile('delnd.mat')
                save('delnd.mat', 'cell_delnd_sumMVA', '-append');
            else
                save('delnd.mat', 'cell_delnd_sumMVA');
            end
        case 'sumPMAX'
            cell_delnd_sumPMAX = cell_delnd;

            write_folder('C:\Users\bxl180002\git\matpower\Dorcas\node\sumPMAX', samplend);
            if isfile('delnd.mat')
                save('delnd.mat', 'cell_delnd_sumPMAX', '-append');
            else
                save('delnd.mat', 'cell_delnd_sumPMAX');
            end
        case 'baseKV'
            cell_delnd_baseKV = cell_delnd;

            write_folder('C:\Users\bxl180002\git\matpower\Dorcas\node\baseKV', samplend);
            if isfile('delnd.mat')
                save('delnd.mat', 'cell_delnd_baseKV', '-append');
            else
                save('delnd.mat', 'cell_delnd_baseKV');
            end
    end
end

%% Save for Dorcas
clear;
load('delnd.mat', 'cell_delnd');
dirhome = 'C:\Users\bxl180002\git\matpower';
dirwork = 'C:\Users\bxl180002\git\matpower\Dorcas';

% Edge, random
cd(dirwork);
cd('node');
cd('random');
dirparent = pwd;
cell_write = cell_delnd;
for j = 1: size(cell_write, 2)
    item = cell_write{end, j};
    if isempty(item)
        continue;
    end
    csvname = strcat(int2str(j), '.csv');
    csvwrite(csvname, item);
end
cd(dirhome);
