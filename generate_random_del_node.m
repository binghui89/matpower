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

