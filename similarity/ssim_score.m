function [simBA, simAB, simSym] = ssim_score(quantA, quantB, idBA, idAB, PARAMS)
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
% Similarity scores computation between point clouds A and B, based on
%   per-attribute quantities (for feature maps) and association indices
%   (for error maps). The type of the estimator to extract feature maps,
%   as well as the pooling method and the reference point cloud to compute 
%   the similarity score, can be manually specified.
%
%   [simBA, simAB, simSym] = ssim_score(quantA, quantB, idBA, idAB, PARAMS)
%
%   INPUTS
%       quantA: Per-attribute quantities that reflect local properties of
%           point cloud A, defined per local region. The size is NxK, with 
%           N the number of points in the point cloud, and K the number of 
%           points comprising the local region
%       quantB: Per-attribute quantities that reflect local properties of
%           point cloud B, defined per local region. The size is MxK, with 
%           M the number of points in the point cloud, and K the number of 
%           points comprising the local region
%       idBA: Indices for the nearest points of B in A. The size is Mx1
%       idAB: Indices for the nearest points of A in B. The size is Nx1
%       PARAMS: Structure of parameters for the computation of similarity
%           scores, with the following fields:
%           ATTRIBUTES - Struct to define which attribute-related features
%               will be used to compute similarity scores, with the
%               following fields:
%                  GEOM - Boolean to enable geometry-related features
%                  NORM - Boolean to enable normal-related features
%                  CURV - Boolean to enable curvature-related features
%                  COLOR - Boolean to enable color-related features
%               More than one options can be enabled
%           ESTIMATOR_TYPE - Defines the estimator(s) for computing
%               statistical dispersion, with available options {'Variance',
%               'Median', 'MeanAD', 'MedianAD', 'COV', 'QCD'}.
%               More than one options can be enabled
%           POOLING_TYPE - Defines the pooling method to compute a total
%               quality score, with available options {'Mean', 'Min',
%               'Max', 'Median', 'RMS', 'MSE'}.
%               More than one options can be enabled
%           REGION_SIZE - Defines the number of nearest neighbors over
%               which the estimator(s) will be applied
%           CONST - Defines a constant that is included in the relative
%               difference computation to avoid undefined operations
%           REF - Defines if symmetric and/or asymmetric similarity scores
%               will be computed, with available options {0: Similarity
%               scores using both point clouds as reference, plus
%               symmetric similarity score, 1: Similarity scores using
%               point cloud A as reference, 2: Similarity scores using
%               point cloud B as reference}
%
%   OUTPUTS
%       simBA: Similarity scores of point cloud B, using A as reference.
%           The size is ExP, with E the length of ESTIMATOR_TYPE and P the
%           length of POOLING_TYPE
%       simAB: Similarity scores of point cloud A, using A as reference.
%           The size is ExP, with E the length of ESTIMATOR_TYPE and P the
%           length of POOLING_TYPE
%       simSym: Symmetric similarity scores. The size is ExP, with E the
%           length of ESTIMATOR_TYPE and P the length of POOLING_TYPE


simBA = [];
simAB = [];
simSym = [];
%%% distBA = [];
%%% distAB = [];
%%% distSym = [];


%% Feature map extraction
[featMapA] = feature_map(quantA, PARAMS.ESTIMATOR_TYPE);
[featMapB] = feature_map(quantB, PARAMS.ESTIMATOR_TYPE);


%% Similarity score of B (set A as reference)
if PARAMS.REF == 0 || PARAMS.REF == 1
    simBA = zeros(length(PARAMS.ESTIMATOR_TYPE), length(PARAMS.POOLING_TYPE));
%%%     distBA = zeros(length(PARAMS.ESTIMATOR_TYPE), length(PARAMS.POOLING_TYPE));
    for i = 1:length(PARAMS.ESTIMATOR_TYPE)
        [errorMapBA] = error_map(featMapB(:,i), featMapA(:,i), idBA, PARAMS.CONST);    % Computation of error map
        simMapBA = 1 - errorMapBA;                                              % Similarity map as 1 - error_map
        [simBA(i,:)] = pooling(simMapBA, PARAMS.POOLING_TYPE);                  % Pooling across map to obtain a quality score
%%%         [distBA(i,:)] = pooling(errorMapBA, PARAMS.POOLING_TYPE);
    end
end


%% Similarity score of A (set B as reference)
if PARAMS.REF == 0 || PARAMS.REF == 2
    simAB = zeros(length(PARAMS.ESTIMATOR_TYPE), length(PARAMS.POOLING_TYPE));
%%%     distAB = zeros(length(PARAMS.ESTIMATOR_TYPE), length(PARAMS.POOLING_TYPE));
    for i = 1:length(PARAMS.ESTIMATOR_TYPE)
        [errorMapAB] = error_map(featMapA(:,i), featMapB(:,i), idAB, PARAMS.CONST);    % Computation of error map
        simMapAB = 1 - errorMapAB;                                              % Similarity map as 1 - error_map
        [simAB(i,:)] = pooling(simMapAB, PARAMS.POOLING_TYPE);                  % Pooling across map to obtain a quality score
%%%         [distAB(i,:)] = error_pooling(errorMapAB, PARAMS.POOLING_TYPE);
    end
end


%% Symmetric similarity score
if PARAMS.REF == 0
    simSym = min(simBA, simAB);     % Maximum error, or minimum similarity
%%%     distSym = max(distBA, distAB);
end
