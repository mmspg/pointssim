function [sim] = pc_ssim(pcA, pcB, PARAMS)
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
% Similarity scores between point clouds pcA and pcB. For each point cloud,
%   a feature map is extracted using statistical dispersion estimators on
%   per-attribute quantities in local regions (i.e., neighborhoods). An 
%   error map is obtained as the relative difference between associated
%   feature maps, and a similarity score is computed after pooling over the
%   error map. A similarity score is obtained per attribute, and depends
%   on the estimator, the pooling method, the size of the local region, and
%   the point cloud that is used as reference. Such parameters can be
%   configured in PARAMS.
%
%   [sim] = pc_ssim(pcA, pcB, PARAMS)
%
%   INPUTS
%       pcA, pcB: Custom point cloud structures, with the following fields:
%           geom - Geometry of point cloud. The size is Nx3
%           norm - Normal vectors of point cloud. The size is Nx3
%           curv - Curvatures of point cloud. The size is Nx1
%           color - RGB color values of point cloud. The size is Nx3
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
%       sim: Structure with similarity scores for different ATTRIBUTES,
%           ESTIMATOR_TYPE, and POOLING_TYPE, depending on the PARAMS


if nargin < 2
    error('Too few input arguments.');
elseif nargin == 2
    if isempty(pcA.geom) || isempty(pcB.geom)
        error('No coordinates found in input point cloud(s).');
    else
        % Deafult parameters
        PARAMS.ATTRIBUTES.GEOM = true;
        PARAMS.ATTRIBUTES.NORM = true;
        PARAMS.ATTRIBUTES.CURV = true;
        PARAMS.ATTRIBUTES.COLOR = true;

        PARAMS.ESTIMATOR_TYPE = {'Variance', 'Median', 'MeanAD', 'MedianAD', 'COV', 'QCD'};
        PARAMS.POOLING_TYPE = {'Mean', 'Median', 'RMS', 'MSE'};
        PARAMS.REGION_SIZE = 12;
        PARAMS.CONST = eps(1);
        PARAMS.REF = 0;
    end
end



%% Conversion to double
A = structfun(@double, pcA, 'UniformOutput', false);
B = structfun(@double, pcB, 'UniformOutput', false);


%% Association of neighborhoods between point clouds A and B
% Loop over B and find nearest neighbor in A (set A as the reference)
[idBA, ~] = knnsearch(A.geom, B.geom);
% Loop over A and find nearest neighbor in B (set B as the reference)
[idAB, ~] = knnsearch(B.geom, A.geom);


%% Formulation of neighborhoods in point clouds A and B
[idA, distA] = knnsearch(A.geom, A.geom, 'K', PARAMS.REGION_SIZE);
[idB, distB] = knnsearch(B.geom, B.geom, 'K', PARAMS.REGION_SIZE);


%% Similarity scores based on geometry-related features
if PARAMS.ATTRIBUTES.GEOM
    % Quantities as distances between a point and each neighbor
    geomQuantA = distA(:, 2:end);
    geomQuantB = distB(:, 2:end);

    % Similarity score(s)
    [sim.geomBA, sim.geomAB, sim.geomSym] = ssim_score(geomQuantA, geomQuantB, idBA, idAB, PARAMS);

    fprintf('Similarity scores based on geometry-related features\n');
end


%% Similarity scores based on normal-related features
if PARAMS.ATTRIBUTES.NORM && ~isempty(A.norm) && ~isempty(B.norm)
    % Quantities as normal similarities between a point and each neighbor
    nsA = real( (pi - 2*acos(abs(sum( A.norm(idA,:).*repmat(A.norm,[PARAMS.REGION_SIZE,1]) ,2))))/pi );
    normQuantA = reshape(nsA, [size(nsA,1)/PARAMS.REGION_SIZE, PARAMS.REGION_SIZE]);
    nsB = real( (pi - 2*acos(abs(sum( B.norm(idB,:).*repmat(B.norm,[PARAMS.REGION_SIZE,1]) ,2))))/pi );
    normQuantB = reshape(nsB, [size(nsB,1)/PARAMS.REGION_SIZE, PARAMS.REGION_SIZE]);
    normQuantA(:,1) = [];
    normQuantB(:,1) = [];

    % Similarity score(s)
    [sim.normBA, sim.normAB, sim.normSym] = ssim_score(normQuantA, normQuantB, idBA, idAB, PARAMS);

    fprintf('Similarity scores based on normal-related features\n');
end


%% Similarity scores based on curvature-related features
if PARAMS.ATTRIBUTES.CURV && ~isempty(A.curv) && ~isempty(B.curv)
    % Quantities as curvature of points that belong to the neighborhood
    curvQuantA = real(A.curv(idA));
    curvQuantB = real(B.curv(idB));

    % Similarity score(s)
    [sim.curvBA, sim.curvAB, sim.curvSym] = ssim_score(curvQuantA, curvQuantB, idBA, idAB, PARAMS);

    fprintf('Similarity scores based on curvature-related features\n');
end


%% Similarity scores based on color-related features
if PARAMS.ATTRIBUTES.COLOR && ~isempty(A.color) && ~isempty(B.color)
    % Quantities as luminance of points that belong to the neighborhood
    [yA, ~, ~] = rgb_to_yuv(A.color(:,1), A.color(:,2), A.color(:,3));
    [yB, ~, ~] = rgb_to_yuv(B.color(:,1), B.color(:,2), B.color(:,3));
    colorQuantA = double(yA(idA));
    colorQuantB = double(yB(idB));

    % Similarity score(s)
    [sim.colorBA, sim.colorAB, sim.colorSym] = ssim_score(colorQuantA, colorQuantB, idBA, idAB, PARAMS);

    fprintf('Similarity scores based on color-related features\n');
end
