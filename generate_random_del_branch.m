clear;
tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
[unique_branch, i_d2u, i_u2d] = unique(tx2kb.branch(:, 1:2), 'rows');

nI = 10;
nJ = 50;
cell_delbr = cell(nI, nJ);

for j = 1: nJ
    ndel = 10*nI;
    iunique_removed = randsample(1:size(unique_branch, 1), ndel);
    branchdel = unique_branch(iunique_removed, :);
    for i = 1: nI
        cell_delbr{i, j} = branchdel(1: i*10, :);
    end
end

save('delbr.mat', 'nI', 'nJ', 'cell_delbr');
%% Generate random edge deletion based on criteria
clear;
tic;
tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
tx2kb.gen(strcmp(tx2kb.gentype, 'W2'), 9:10) = 0; % Remove wind generators
tx2kb.gen(strcmp(tx2kb.gentype, 'PV'), 9:10) = 0; % Remove wind generators

nI = 10;
nJ = 50;

criteria = {'sumdegree', 'MVA'};

for k = 1: numel(criteria)
    cell_delbr = cell(nI, nJ);
    edge_unique_sorted = edge_order_by(criteria{k});
    
    ndel = 10*nI;
    samplebr = random_sample_given_nrow(edge_unique_sorted, ndel, nJ);

    for j = 1: size(samplebr, 3)
        for i = 1: nI
            cell_delbr{i, j} = samplebr(1: i*10, 1:2, j);
        end
    end
        
    switch criteria{k}
        case 'sumdegree'
            cell_delbr_sumdegree = cell_delbr;
            
            write_folder('C:\Users\bxl180002\git\matpower\Dorcas\edge\sumdegree', samplebr);
            if isfile('delbr.mat')
                save('delbr.mat', 'cell_delbr_sumdegree', '-append');
            else
                save('delbr.mat', 'cell_delbr_sumdegree');
            end
            
        case 'MVA'
            cell_delbr_MVA = cell_delbr;

            write_folder('C:\Users\bxl180002\git\matpower\Dorcas\edge\MVA', samplebr);
            if isfile('delbr.mat')
                save('delbr.mat', 'cell_delbr_MVA', '-append');
            else
                save('delbr.mat', 'cell_delbr_MVA');
            end
    end
end

%% Save for Dorcas
clear;
load('delbr.mat', 'cell_delbr');
dirhome = 'C:\Users\bxl180002\git\matpower';
dirwork = 'C:\Users\bxl180002\git\matpower\Dorcas';

% Edge, random
cd(dirwork);
cd('edge');
cd('random');
dirparent = pwd;
cell_write = cell_delbr;
for j = 1: size(cell_write, 2)
    item = cell_write{end, j};
    if isempty(item)
        continue;
    end
    csvname = strcat(int2str(j), '.csv');
    csvwrite(csvname, item);
end
cd(dirhome);
