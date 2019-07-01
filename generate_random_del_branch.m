tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
[unique_branch, i_d2u, i_u2d] = unique(tx2kb.branch(:, 1:2), 'rows');

nI = 10;
nJ = 300;
cell_delbr = cell(nI, nJ);

for i = 1: nI
    for j = 1: nJ
        ndel = 10*i;
        iunique_removed = randsample(1:size(unique_branch, 1), ndel);
        branchdel = unique_branch(iunique_removed, :);
        cell_delbr{i, j} = branchdel;
    end
end

save('delbr.mat', 'nI', 'nJ', 'cell_delbr', 'tx2kb', 'unique_branch');

%% Add nI = 11 to 20, nJ reduced from 300 to 200
load('delbr_old.mat', 'cell_delbr');
tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
[unique_branch, i_d2u, i_u2d] = unique(tx2kb.branch(:, 1:2), 'rows');

cell_delbr_old = cell_delbr;

nI = 20;
nJ = 200;
cell_delbr = cell(nI, nJ);
cell_delbr(1: 10, 1: nJ) = cell_delbr_old(:, 1:nJ);
for i = 11: 20
    for j = 1: nJ
        ndel = 10*i;
        iunique_removed = randsample(1:size(unique_branch, 1), ndel);
        branchdel = unique_branch(iunique_removed, :);
        cell_delbr{i, j} = branchdel;
    end
end
save('delbr.mat', 'nI', 'nJ', 'cell_delbr', 'tx2kb', 'unique_branch');