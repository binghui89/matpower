function mpc_new = remove_br1(mpc, branchdel)
% Each row of branchdel includes unique from_bus-to_bus pair.
define_constants;

% [unique_branch, i_d2u, i_u2d] = unique(mpc.branch(:, 1:2), 'rows');
mpc_new = mpc;

% mpc.branch(ismember(i_u2d, iunique_removed), :) = []; % Remove branches
mpc_new.branch(ismember(mpc_new.branch(:, 1:2), branchdel, 'rows'), BR_STATUS) = 0; % Remove branches
% bus_remain = unique(mpc.branch(:, 1:2));
% 
% % Remove isolated buses
% mpc.bus = mpc.bus(ismember(mpc.bus(:, 1), bus_remain), :);
% 
% % Remove isolated gens.
% mpc.gen = mpc.gen(ismember(mpc.gen(:, GEN_BUS), bus_remain), :);
% mpc.gentype = mpc.gentype(ismember(mpc.gen(:, GEN_BUS), bus_remain), :);
% mpc.genfuel = mpc.genfuel(ismember(mpc.gen(:, GEN_BUS), bus_remain), :);
% mpc.gencost = mpc.gencost(ismember(mpc.gen(:, GEN_BUS), bus_remain), :);

end