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
% This is a simple example of how to run the pointssim metric. 
%   In this example, voxelization is not used. Normals and curvatures are
%   estimated through the provided script using range-search and setting
%   radius equal to 1% of the maximum length of the minimum bounding box of
%   the original content. Structural similarity scores are computed using 
%   normal-, curvature- and color-based features, with 'VAR' and 'Mean' as 
%   statistical estimators, 'Mean' as the pooling method, 12 points as 
%   neighborhood size, and both point clouds as reference.
% 
%   'Mean' is not an estimator of dispersion, however, it is included as it
%   might be useful for determining the center of the samples distribution.
% 
%   Normals and curvatures may be given or estimated through other software
%   implementations (e.g., CloudCompare). In this case, they should be
%   loaded and assigned to corresponding fields of custom structs that are
%   used for point clouds (see sA and sB below), but after considering the
%   geometry sorting, point fusion and voxelization steps that take place 
%   below (i.e., attributes should be estimated on the resulting geomerty). 
%   In all cases, the same software implementation and the same
%   configuration (e.g., neighborhood size) should be used to estimate
%   normals/curvatures, for both the original and the distorted contents.


clear all;
close all;
clc;


%% Configurations
PARAMS.ATTRIBUTES.GEOM = false;
PARAMS.ATTRIBUTES.NORM = true;
PARAMS.ATTRIBUTES.CURV = true;
PARAMS.ATTRIBUTES.COLOR = true;

PARAMS.ESTIMATOR_TYPE = {'VAR', 'Mean'};
PARAMS.POOLING_TYPE = {'Mean'};
PARAMS.NEIGHBORHOOD_SIZE = 12;
PARAMS.CONST = eps(1);
PARAMS.REF = 0;

FITTING.SEARCH_METHOD = 'rs';
if strcmp(FITTING.SEARCH_METHOD, 'rs')
    ratio = 0.01;
elseif strcmp(FITTING.SEARCH_METHOD, 'knn')
    knn = 12;
end
FITTING.SEARCH_SIZE = [];

QUANT.VOXELIZATION = false;
QUANT.TARGET_BIT_DEPTH = 9;


%% Load point clouds
A = pcread('original.ply');
B = pcread('distorted.ply');


%% Sort geometry
[geomA, idA] = sortrows(A.Location);
if ~isempty(A.Color)
    colorA = A.Color(idA, :);
    A = pointCloud(geomA, 'Color', colorA);
else
    A = pointCloud(geomA);
end

[geomB, idB] = sortrows(B.Location);
if ~isempty(B.Color)
    colorB = B.Color(idB, :);
    B = pointCloud(geomB, 'Color', colorB);
else
    B = pointCloud(geomB);
end


%% Point fusion
A = pc_fuse_points(A);
B = pc_fuse_points(B);


%% Voxelization
if QUANT.VOXELIZATION
    A = pc_vox_scale(A, [], QUANT.TARGET_BIT_DEPTH);
    B = pc_vox_scale(B, [], QUANT.TARGET_BIT_DEPTH);
end


%% Normals and curvatures estimation
if PARAMS.ATTRIBUTES.NORM || PARAMS.ATTRIBUTES.CURV
    if strcmp(FITTING.SEARCH_METHOD, 'rs')
        FITTING.SEARCH_SIZE = round(ratio * double(max(max(A.Location) - min(A.Location))));
    else
        FITTING.SEARCH_SIZE = knn;
    end
    [normA, curvA] = pc_estimate_norm_curv_qfit(A, FITTING.SEARCH_METHOD, FITTING.SEARCH_SIZE);
    [normB, curvB] = pc_estimate_norm_curv_qfit(B, FITTING.SEARCH_METHOD, FITTING.SEARCH_SIZE);
end


%% Set custom structs with required fields
sA.geom = A.Location;
sB.geom = B.Location;
if PARAMS.ATTRIBUTES.NORM
    sA.norm = normA;
    sB.norm = normB; 
end
if PARAMS.ATTRIBUTES.CURV
    sA.curv = curvA;
    sB.curv = curvB;
end
if PARAMS.ATTRIBUTES.COLOR
    sA.color = A.Color;
    sB.color = B.Color;
end


%% Compute structural similarity scores
[pssim] = pointssim(sA, sB, PARAMS);

