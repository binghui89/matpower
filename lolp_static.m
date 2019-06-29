function loss_of_load = lolp_static(mpc)
% cell_islands is a cell of matpower instances
cell_islands = extract_islands(mpc);
nislands = numel(cell_islands);
sigma_pmax = nan(nislands, 1);
sigma_demand = nan(nislands, 1);
for i = 1: nislands
    mpc = cell_islands{i};
    sigma_pmax(i)   = sum(mpc.gen(:, 9)); % PMAX
    sigma_demand(i) = sum(mpc.bus(:, 3));  % PD
end

loss_of_load = any(sigma_pmax<sigma_demand);

end