function [ssimBA, ssimAB, ssimSym] = ssim_score(quantA, quantB, idBA, idAB, PARAMS)
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
% Structural similarity scores computation between point clouds A and B
%   based on per-attribute quantities, neighbohood associations, and
%   parameters configuration in the struct PARAMS.
%
%   [ssimBA, ssimAB, ssimSym] = ssim_score(quantA, quantB, idBA, idAB, PARAMS)
%
%   INPUTS
%       quantA: Per-attribute quantities that reflect corresponding local
%           properties of point cloud A. The size is NxK, with N the number
%           of points of A, and K the number of points comprising the local
%           neighborhood.
%       quantB: Per-attribute quantities that reflect corresponding local
%           properties of point cloud B. The size is MxK, with M the number
%           of points of B, and K the number of points comprising the local
%           neighborhood.
%       idBA: Indices to associate points from B in A. The size is Mx1.
%       idAB: Indices to associate points from A in B. The size is Nx1.
%       PARAMS: Struct of parameters for the computation of structural
%           similarity scores, with the following fields:
%           ATTRIBUTES - Defines the attribute-related feature(s) that will
%               be used to compute structural similarity scores, with the
%               following fields:
%                  GEOM - Boolean to enable geometry-related features.
%                  NORM - Boolean to enable normal-related features.
%                  CURV - Boolean to enable curvature-related features.
%                  COLOR - Boolean to enable color-related features.
%               More than one options can be enabled.
%           ESTIMATOR_TYPE - Defines the estimator(s) that will be used to
%               compute statistical dispersion, with available options:
%               {'STD', 'VAR', 'MeanAD', 'MedianAD', 'COV', 'QCD'}.
%               More than one options can be enabled.
%           POOLING_TYPE - Defines the pooling method(s) that will be used
%               to compute a total quality score, with available options:
%               {'Mean', 'MSE', 'RMS'}.
%               More than one options can be enabled.
%           NEIGHBORHOOD_SIZE - Defines the number of nearest neighbors
%               over which the estimator(s) will be applied.
%           CONST - Defines a constant that is included in the relative
%               difference computation to avoid undefined operations.
%           REF - Defines if symmetric and/or asymmetric structural
%               similarity scores will be computed, with available options:
%               {0: Both point clouds as reference, 1: Point cloud A as
%               reference, 2: Point cloud B as reference}.
%
%   OUTPUTS
%       ssimBA: Structural similarity scores of point cloud B, using A as
%           reference. The size is ExP, with E the length of ESTIMATOR_TYPE
%           and P the length of POOLING_TYPE.
%       ssimAB: Structural similarity scores of point cloud A, using B as
%           reference. The size is ExP, with E the length of ESTIMATOR_TYPE
%           and P the length of POOLING_TYPE.
%       ssimSym: Symmetric structural similarity scores, using both A and B
%           as reference. The size is ExP, with E the length of
%           ESTIMATOR_TYPE and P the length of POOLING_TYPE.


ssimBA = [];
ssimAB = [];
ssimSym = [];
%%% errorBA = [];
%%% errorAB = [];
%%% errorSym = [];


%% Feature map extraction
[featMapA] = feature_map(quantA, PARAMS.ESTIMATOR_TYPE);
[featMapB] = feature_map(quantB, PARAMS.ESTIMATOR_TYPE);


%% Structucal similarity score of B (set A as reference)
if PARAMS.REF == 0 || PARAMS.REF == 1
    ssimBA = zeros(length(PARAMS.ESTIMATOR_TYPE), length(PARAMS.POOLING_TYPE));
%%%     errorBA = zeros(length(PARAMS.ESTIMATOR_TYPE), length(PARAMS.POOLING_TYPE));
    for i = 1:length(PARAMS.ESTIMATOR_TYPE)
        [errorMapBA] = error_map(featMapB(:,i), featMapA(:,i), idBA, PARAMS.CONST);    % Computation of error map
        ssimMapBA = 1 - errorMapBA;                                               % Similarity map as 1 - error_map
        [ssimBA(i,:)] = pooling(ssimMapBA, PARAMS.POOLING_TYPE);                  % Pooling across map to obtain a quality score
%%%         [errorBA(i,:)] = pooling(errorMapBA, PARAMS.POOLING_TYPE);
    end
end


%% Structucal similarity score of A (set B as reference)
if PARAMS.REF == 0 || PARAMS.REF == 2
    ssimAB = zeros(length(PARAMS.ESTIMATOR_TYPE), length(PARAMS.POOLING_TYPE));
%%%     errorAB = zeros(length(PARAMS.ESTIMATOR_TYPE), length(PARAMS.POOLING_TYPE));
    for i = 1:length(PARAMS.ESTIMATOR_TYPE)
        [errorMapAB] = error_map(featMapA(:,i), featMapB(:,i), idAB, PARAMS.CONST);    % Computation of error map
        ssimMapAB = 1 - errorMapAB;                                               % Similarity map as 1 - error_map
        [ssimAB(i,:)] = pooling(ssimMapAB, PARAMS.POOLING_TYPE);                  % Pooling across map to obtain a quality score
%%%         [errorAB(i,:)] = error_pooling(errorMapAB, PARAMS.POOLING_TYPE);
    end
end


%% Symmetric structucal similarity score
if PARAMS.REF == 0
    ssimSym = min(ssimBA, ssimAB);     % Maximum error, or minimum similarity
%%%     errorSym = max(errorBA, errorAB);
end
