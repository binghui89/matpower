function mpc_new = remove_nd(mpc, delbus)
% Remove buses specified in delbus, delbus must be a column vector
% including all unique bus indices that will be removed

mpc_new = mpc;
mpc_new.bus(ismember(mpc_new.bus(:, 1), delbus), :) = [];
mpc_new.branch(ismember(mpc_new.branch(:, 1), delbus) | ismember(mpc_new.branch(:, 2), delbus), :) = [];
mpc_new.gen(ismember(mpc_new.gen(:, 1), delbus), :) = [];
mpc_new.gencost(ismember(mpc_new.gen(:, 1), delbus), :) = [];
mpc_new.gentype(ismember(mpc_new.gen(:, 1), delbus), :) = [];
mpc_new.genfuel(ismember(mpc_new.gen(:, 1), delbus), :) = [];

end