function [score] = pooling(qMap, POOLING_TYPE)
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
% Quality score for a point cloud, based on pooling over the corresponding
%   quality map. A quality map can contain either distance (error) or
%   similarity values.
%
%   [score] = pooling(qMap, POOLING_TYPE)
%
%   INPUTS
%       qMap: Quality map of a point cloud
%       POOLING_TYPE: Defines the pooling method to compute a total quality
%           score, with available options {'Mean', 'Min', 'Max', 'Median', 
%           'RMS', 'MSE'}.
%           More than one options can be enabled
%
%   OUTPUTS
%       score: Quality score of a point cloud. The size is 1xP, with P the 
%           length of POOLING_TYPE


score = zeros(1, length(POOLING_TYPE));

k = 1;
for i = 1:length(POOLING_TYPE)
    if strcmp(POOLING_TYPE{i}, 'Mean')
        score(k) = nanmean(qMap);

    elseif strcmp(POOLING_TYPE{i}, 'Min')
        score(k) = nanmin(qMap);

    elseif strcmp(POOLING_TYPE{i}, 'Max')
        score(k) = nanmax(qMap);

    elseif strcmp(POOLING_TYPE{i}, 'Median')
        score(k) = nanmedian(qMap);

    elseif strcmp(POOLING_TYPE{i}, 'RMS')
        score(k) = sqrt(nanmean(qMap.^2));

    elseif strcmp(POOLING_TYPE{i}, 'MSE')
        score(k) = nanmean(qMap.^2);

    else
        error('WrongInput');
    end
    k = k+1;
end
