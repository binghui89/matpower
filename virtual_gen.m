function [mpc_v, gen_is_virtual] = virtual_gen(mpc)
% Add virtual generators at all load buses

i_load_bus = mpc.bus(:, 3)>0;
load_bus = mpc.bus(i_load_bus, 1);
nv = size(load_bus, 1);

load_bus_v = mpc.bus(i_load_bus, 1);
pg_v = zeros(nv, 1);
qg_v = zeros(nv, 1);
qmax_v = mpc.bus(i_load_bus, 4); % Reactive load
qmin_v = zeros(nv, 1);
vg_v = zeros(nv, 1);
mbase_v = mpc.baseMVA.*ones(nv, 1);
gen_status_v = ones(nv, 1);
pmax_v = mpc.bus(i_load_bus, 3); % Real load
pmin_v = zeros(nv, 1);
pc1_v = zeros(nv, 1);
pc2_v = zeros(nv, 1);
qc1min_v = zeros(nv, 1);

gen_v = [load_bus_v, pg_v, qg_v, qmax_v, qmin_v, vg_v, mbase_v, gen_status_v, pmax_v, pmin_v, zeros(nv, 15)];

cost_model_v = 2.*ones(nv, 1); % Polynomial cost function
startup_v  = zeros(nv, 1);
shutdown_v = zeros(nv, 1);
ncost_v = 3.*ones(nv, 1); % Quadratic cost function, 3 coefficients
c2_v = zeros(nv, 1); % Quadratic terms
c1_v = 1E5.*ones(nv, 1); % Linear terms
c0_v = zeros(nv, 1); % Constant terms

gencost_v = [cost_model_v, startup_v, shutdown_v, ncost_v, c2_v, c1_v, c0_v];

gentype_v = repmat({'GT'}, nv, 1);

genfuel_v = repmat({'ng'}, nv, 1);

mpc_v = mpc;
mpc_v.gen = [mpc_v.gen; gen_v];
mpc_v.gencost = [mpc_v.gencost; gencost_v];
mpc_v.gentype = [mpc_v.gentype; gentype_v];
mpc_v.genfuel = [mpc_v.genfuel; genfuel_v];

gen1 = false(size(mpc.gen, 1), 1);
gen2 = true(nv, 1);
gen_is_virtual = [gen1; gen2];

end