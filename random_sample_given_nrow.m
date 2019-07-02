function randomsample = random_sample_given_nrow(M, nrow, nsample)
% The rows of M should be in descending order. The last column is the 
% ranking criteria. 
% nrow is the number of rows in each sample
% nsample is the number of generated samples
% Output: 3-d array: nrow x size(M, 2) -1 x nsample

[r, c] = size(M);
value_nrow = M(nrow, end); % This is the criteria value of the last rank

nrow1 = size(M(M(:, end) > value_nrow, :), 1); % The part that is fixed
nrow2 = size(M(M(:, end) >= value_nrow, :), 1);

sample_seed = M(M(:, end)==value_nrow, :);
nseed = size(sample_seed, 1);
nsample_max = nchoosek(nseed, nrow-nrow1); % This is the maximum possible number of samples

randomsample = nan(nrow, c-1, min(nsample_max, nsample));

M_fixed = M(1:nrow1, :);
for i = 1: size(randomsample, 3)
    isample = randsample(1: nseed, nseed);
    this_sample = sample_seed(isample, :);
    randomsample(:, :, i) = [M_fixed(:, 1:c-1); this_sample(1:nrow-nrow1, 1: c-1)];
end


end