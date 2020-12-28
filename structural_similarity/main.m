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
% This is a simple script that serves as an example of a main. The function
%   "pc_ssim" takes as arguments two custom structs with fields that
%   correspond to the point cloud attributes on which the structural
%   similarity will be computed. Note that "geom" field is mandatory in
%   order to permit neighborhood formulations and associations. The PARAMS
%   struct is used to configure the computation of structural similarity
%   scores.
%
%   Below you can find an example for the computation of structural
%   similarity scores using color-based features, with 'VAR' as the
%   dispersion estimator, 'Mean' as the pooling method, 12 points as the
%   neighborhood size, and using both point clouds as reference.


clear all;
close all;
clc;


%% Load point clouds
a = pcread('pointcloudA.ply');
b = pcread('pointcloudB.ply');


%% Define structs with required fields
pcA.geom = a.Location;
pcA.color = a.Color;

pcB.geom = b.Location;
pcB.color = b.Color;


%% Configure PARAMS
PARAMS.ATTRIBUTES.GEOM = false;
PARAMS.ATTRIBUTES.NORM = false;
PARAMS.ATTRIBUTES.CURV = false;
PARAMS.ATTRIBUTES.COLOR = true;

PARAMS.ESTIMATOR_TYPE = {'VAR'};
PARAMS.POOLING_TYPE = {'Mean'};
PARAMS.NEIGHBORHOOD_SIZE = 12;
PARAMS.CONST = eps(1);
PARAMS.REF = 0;


%% Compute structural similarity values based on selected PARAMS
[pointssim] = pc_ssim(pcA, pcB, PARAMS);
