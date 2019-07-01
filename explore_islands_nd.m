%% Random attack

clear;
tic;
load('delnd.mat');
tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');

load_matrix = csvread('./ACTIVSg2000/Jubeyer/Texas_2k_load.csv', 1, 1);
load_matrix(:, end) = []; % This column is total load
i_loadbus = tx2kb.bus(:, 3)>0;


nislands_random = nan(nI, nJ);
lolp_random     = nan(nI, nJ);
nnode_remove    = nan(nI, 1);

for i = 1: nI
    for j = 1: nJ % Just repeat 10 times per attack
        
        loss_of_load = nan(size(load_matrix, 1)/24, 1);
        
        nodedel = cell_delnd{i, j};

        parfor d = 1: size(load_matrix, 1)/24
            
            load_day = load_matrix(24*(d-1)+1: 24*d, :);
            [~, imax] = max(sum(load_day, 2));
            
            test = tx2kb;
            test.bus(i_loadbus, 3) = load_day(imax, :)';
            test = remove_nd(test, nodedel);
            loss_of_load(d) = lolp_static(test);

        end
        
        test = remove_nd(tx2kb, nodedel);
        cell_islands = extract_islands(test);
        nislands_random(i, j) = numel(cell_islands);
        lolp_random(i, j) = sum(loss_of_load)/numel(loss_of_load);

    end
    nnode_remove(i) = size(nodedel, 1);
    toc;
end

if isfile('explore_islands_nd.mat')
    save('explore_islands_nd.mat', 'nislands_random', 'lolp_random', 'nnode_remove', '-append');
else
    save('explore_islands_nd.mat', 'nislands_random', 'lolp_random', 'nnode_remove');
end

%% By criteria

% clear;
% tx2kb = loadcase('./ACTIVSg2000/case_ACTIVSg2000.m');
% [edge_unique, i_d2u, i_u2d] = unique(tx2kb.branch(:, 1:2), 'rows');
% 
% load_matrix = csvread('./ACTIVSg2000/Jubeyer/Texas_2k_load.csv', 1, 1);
% load_matrix(:, end) = []; % This column is total load
% i_loadbus = tx2kb.bus(:, 3)>0;
% nd = size(load_matrix,1);
% 
% remove_by = {'degree'; 'sumMVA' ; 'sumPMAX'; 'baseKV'};
% 
% 
% for k = 1: size(remove_by, 1)
%     remove_by_this = remove_by{k};
%     node_descend = node_order_by(remove_by_this);
% 
%     nnode_remove = 10: 10: 200;
%     nI = length(nnode_remove);
%     nislands = nan(nI, 1);
%     lolp = nan(nI, 1);
% 
%     for i = 1: nI
%         n_del = nnode_remove(i);
%         nodedel = node_descend(1: n_del, :);
%         loss_of_load = nan(size(load_matrix, 1)/24, 1);
% 
%         parfor d = 1: size(load_matrix, 1)/24
% 
%             load_day = load_matrix(24*(d-1)+1: 24*d, :);
%             [~, imax] = max(sum(load_day, 2));
%             test = tx2kb;
%             test.bus(i_loadbus, 3) = load_day(imax, :)';
% 
%             test = remove_nd(test, nodedel);
%             loss_of_load(d) = lolp_static(test);
% 
%         end
%         lolp(i) = sum(loss_of_load)/numel(loss_of_load);
% 
% 
%         test = remove_nd(tx2kb, nodedel);
%         ndel = size(nodedel, 1);
% 
%         % Display how many isolated islands are left
%         cell_islands = extract_islands(test);
%         nislands(i) = numel(cell_islands);
%     end
%     
%     switch remove_by_this
%         case 'degree'
%             nislands_degree = nislands;
%             lolp_degree = lolp;
% 
%             if isfile('explore_islands_nd.mat')
%                 save('explore_islands_nd.mat', 'nislands_degree', 'lolp_degree', 'nnode_remove', '-append');
%             else
%                 save('explore_islands_nd.mat', 'nislands_degree', 'lolp_degree', 'nnode_remove');
%             end
%     
%         case 'sumMVA'
%             nislands_sumMVA = nislands;
%             lolp_sumMVA = lolp;
% 
%             if isfile('explore_islands_nd.mat')
%                 save('explore_islands_nd.mat', 'nislands_sumMVA', 'lolp_sumMVA', 'nnode_remove', '-append');
%             else
%                 save('explore_islands_nd.mat', 'nislands_sumMVA', 'lolp_sumMVA', 'nnode_remove');
%             end
%             
%         case 'sumPMAX'
%             nislands_sumPMAX = nislands;
%             lolp_sumPMAX = lolp;
%             
%             if isfile('explore_islands_nd.mat')
%                 save('explore_islands_nd.mat', 'nislands_sumPMAX', 'lolp_sumPMAX', 'nnode_remove', '-append');
%             else
%                 save('explore_islands_nd.mat', 'nislands_sumPMAX', 'lolp_sumPMAX', 'nnode_remove');
%             end
% 
%         case 'baseKV'
%             nislands_baseKV = nislands;
%             lolp_baseKV = lolp;
%             
%         if isfile('explore_islands_nd.mat')
%             save('explore_islands_nd.mat', 'nislands_baseKV', 'lolp_baseKV', 'nnode_remove', '-append');
%         else
%             save('explore_islands_nd.mat', 'nislands_baseKV', 'lolp_baseKV', 'nnode_remove');
%         end
% 
%     end
% 
% end
