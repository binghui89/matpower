function final_samples = random_sample_given_nrow(M, nrow, nsample)
% The rows of M should be in descending order. The last column is the 
% ranking criteria. 
% nrow is the number of rows in each sample
% nsample is the number of generated samples
% Output: 3-d array: nrow x size(M, 2) -1 x nsample

[r, c] = size(M);
% value_nrow = M(nrow, end); % This is the criteria value of the last rank
% 
% nrow1 = size(M(M(:, end) > value_nrow, :), 1); % The part that is fixed
% nrow2 = size(M(M(:, end) >= value_nrow, :), 1);
% 
% sample_seed = M(M(:, end)==value_nrow, :);
% nseed = size(sample_seed, 1);
% nsample_max = nchoosek(nseed, nrow-nrow1); % This is the maximum possible number of samples
% 
% randomsample = nan(nrow, c-1, min(nsample_max, nsample));
% 
% M_fixed = M(1:nrow1, :);
% for i = 1: size(randomsample, 3)
%     isample = randsample(1: nseed, nseed);
%     this_sample = sample_seed(isample, :);
%     randomsample(:, :, i) = [M_fixed(:, 1:c-1); this_sample(1:nrow-nrow1, 1: c-1)];
% end

value_nrow = M(nrow, end); % This is the criteria value of the last rank
unique_values = unique(M(1: nrow, end));
unique_values = sort(unique_values, 'descend');

cell_sample = cell(size(unique_values, 1), nsample);
for i = 1: size(unique_values, 1)
    nvalue = size(M(M(1:nrow, end)==unique_values(i), :), 1);
    sample_seed = M(M(:, end)==unique_values(i), :);
    nvalue_all = size(sample_seed, 1);
    nsample_max = min(nsample, factorial(nvalue)*nchoosek(nvalue_all, nvalue));
    randomsample_all = nan(nvalue_all, c, nsample_max);
    if factorial(nvalue)*nchoosek(nvalue_all, nvalue)<=nsample
        all_possible_isample = perms(1: nvalue_all);
        for j = 1: nsample_max
            isample = all_possible_isample(j, :);
            this_sample = sample_seed(isample, :); 
            randomsample_all(:, :, j) = this_sample;
        end
    else
        for j = 1: nsample_max
            isample = randsample(1: nvalue_all, nvalue_all);
            this_sample = sample_seed(isample, :); 
            randomsample_all(:, :, j) = this_sample;
        end
    end
    
    for j = 1: nsample
        j_mod_nsample = mod(j, nsample_max);
        if j_mod_nsample == 0
            j_mod_nsample = nsample_max;
        end
        cell_sample{i, j} = squeeze(randomsample_all(1: nvalue, :, j_mod_nsample));
    end
end

final_samples = nan(nrow, c, nsample);

for i = 1: nsample
    this_sample = [];
    for j = 1: size(cell_sample, 1)
        this_sample = [this_sample; cell_sample{j, i}];
    end
    final_samples(:, :, i) = this_sample;
end

final_samples = unique_sample(final_samples);

end

function sample_unique_3d = unique_sample(sample)
[r, c, p] = size(sample);
sample_unique_2d = unique(reshape(sample, r*c, p)', 'rows')';
p_new = numel(sample_unique_2d)/(r*c);
if p_new == p
    sample_unique_3d = sample;
else
    sample_unique_3d = reshape(sample_unique_2d, r, c, p_new);
end
end