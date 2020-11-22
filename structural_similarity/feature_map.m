function [fMap] = feature_map(quant, ESTIMATOR_TYPE)
% Copyright (C) 2020 ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland
%
%     Multimedia Signal Processing Group (MMSPG)
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%
% Author:
%   Evangelos Alexiou (evangelos.alexiou@epfl.ch)
%
% Reference:
%   E. Alexiou and T. Ebrahimi, "Towards a Point Cloud Structural 
%   Similarity Metric," 2020 IEEE International Conference on Multimedia & 
%   Expo Workshops (ICMEW), London, United Kingdom, 2020, pp. 1-6.
%
%
% Feature map of a point cloud, based on per-attribute quantities and
%   statistical dispersion estimator(s).
%
%   [fMap] = feature_map(quant, ESTIMATOR_TYPE)
%
%   INPUTS
%       quant: Per-attribute quantities that reflect corresponding local
%           properties of a point cloud. The size is LxK, with L the number
%           of points of the point cloud, and K the number of points 
%           comprising the local neighborhood.
%       ESTIMATOR_TYPE - Defines the estimator(s) that will be used to 
%           compute statistical dispersion, with available options: 
%           {'Variance', 'Median', 'MeanAD', 'MedianAD', 'COV', 'QCD'}.
%           More than one options can be enabled.
%
%   OUTPUTS
%       fMap: Feature map of a point cloud, per estimator. The size is LxE, 
%           with L the number of points of the point cloud and E the length 
%           of the ESTIMATOR_TYPE.


fMap = zeros(size(quant,1), length(ESTIMATOR_TYPE));

k = 1;
for i = 1:length(ESTIMATOR_TYPE)
    if strcmp(ESTIMATOR_TYPE{i}, 'Variance')
        fMap(:,k) = var(quant,[],2);

    elseif strcmp(ESTIMATOR_TYPE{i}, 'Median')
        fMap(:,k) = median(quant,2);

    elseif strcmp(ESTIMATOR_TYPE{i}, 'MeanAD')
        fMap(:,k) = mean(abs(quant - mean(quant,2)),2);

    elseif strcmp(ESTIMATOR_TYPE{i}, 'MedianAD')
        fMap(:,k) = median(abs(quant - median(quant,2)), 2);

    elseif strcmp(ESTIMATOR_TYPE{i}, 'COV')
        fMap(:,k) = std(quant,[],2)./mean(quant,2);

    elseif strcmp(ESTIMATOR_TYPE{i}, 'QCD')
        qq = quantile(quant, [.25 .75], 2);
        fMap(:,k) = (qq(:,2) - qq(:,1)) ./ (qq(:,2) + qq(:,1));
    else
        error('WrongInput');
    end
    k = k+1;
end
