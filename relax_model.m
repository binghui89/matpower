function mpc_softlim = relax_model(mpc)

nl = size(mpc.branch, 1);
mpc.softlims.PMAX.hl_mod = 'remove';
mpc.softlims.PMAX.idx = (1: nl)';
mpc.softlims.PMAX.cost = 10000 * ones(nl, 1);

mpc.softlims.RATE_A.hl_mod = 'remove';
mpc.softlims.RATE_A.idx = (1: nl)';
mpc.softlims.RATE_A.cost = 10000 * ones(nl, 1);

mpc.softlims.ANGMIN.hl_mod = 'none';
% mpc.softlims.ANGMIN.hl_mod = 'remove';
% mpc.softlims.ANGMIN.idx = (1: nl)';
% mpc.softlims.ANGMIN.cost = 10000 * ones(nl, 1);

mpc.softlims.ANGMAX.hl_mod = 'none';
% mpc.softlims.ANGMAX.hl_mod = 'remove';
% mpc.softlims.ANGMAX.idx = (1: nl)';
% mpc.softlims.ANGMAX.cost = 10000 * ones(nl, 1);

mpc_softlim = toggle_softlims(mpc, 'on');

end