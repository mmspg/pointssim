function [pssim] = pointssim(sA, sB, PARAMS)
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
% Structural similarity scores between point clouds A and B, which are
%   represented by corresponding custom structs sA and sB. A structural 
%   similarity score is obtained per attribute, namely, geometry, normal, 
%   curvature, and color. In particular, neighborhoods are formulated in A 
%   and B, and then an association between the two is found. In each local  
%   neighborhood, attribute-based quantities are defined. For each point 
%   cloud, a feature map is extracted using a statistical dispersion 
%   estimator on these attribute-based quantities. An error map is obtained 
%   as the relative difference between associated feature maps, and a 
%   structural similarity score is computed via pooling. The structural 
%   similarity score depends on the selected attribute, dispersion  
%   estimator, pooling method, size of the local neighborhood, and  
%   selection of reference point cloud. These parameters can be specified 
%   in the custom struct PARAMS. 
%
%   [pssim] = pointssim(sA, sB, PARAMS)
%
%   INPUTS
%       sA: Custom struct for point cloud A, with fields:
%           geom - Geometry (mandatory field).
%               The size is Nx3, with N the number of points of A.
%           norm - Normals (optional field).
%               The size is Nx3.
%           curv - Curvatures (optional field).
%               The size is Nx1.
%           color - RGB color (optional field).
%               The size is Nx3.
%       sB: Custom struct for point cloud B, with fields:
%           geom - Geometry (mandatory field).
%               The size is Mx3, with M the number of points of B.
%           norm - Normals (optional field).
%               The size is Mx3.
%           curv - Curvatures (optional field).
%               The size is Mx1.
%           color - RGB color (optional field).
%               The size is Mx3.
%       PARAMS: Custom struct of parameters for the computation of 
%           structural similarity scores, with the following fields:
%           ATTRIBUTES - Defines the attribute-based feature(s) that will 
%               be used to compute structural similarity scores, with the
%               following fields:
%                  GEOM - Boolean to enable geometry-based features.
%                  NORM - Boolean to enable normal-based features.
%                  CURV - Boolean to enable curvature-based features.
%                  COLOR - Boolean to enable color-based features.
%               More than one option can be enabled.
%           ESTIMATOR_TYPE - Defines the estimator(s) that will be used to
%               compute statistical dispersion, with available options:
%               {'STD', 'VAR', 'MeanAD', 'MedianAD', 'COV', 'QCD'}.
%               **{'Mean'} has been additionally included as an extra  
%               statistic to estimate the center of the distribution.**
%               More than one option can be enabled.
%           POOLING_TYPE - Defines the pooling method(s) that will be used
%               to compute a total quality score, with available options:
%               {'Mean', 'MSE', 'RMSE'}.
%               More than one option can be enabled.
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
%       pssim: Structural similarity scores for different ATTRIBUTES,
%           ESTIMATOR_TYPE, and POOLING_TYPE, as specified in PARAMS.


if nargin < 2
    error('Too few input arguments.');
else
    if ~isfield(sA,'geom') || ~isfield(sB,'geom')
        error('No coordinates found in input point cloud(s).');
    end
    
    if nargin == 2
        if isfield(sA,'color') && isfield(sB,'color')
            % Default parameters
            PARAMS.ATTRIBUTES.GEOM = false;
            PARAMS.ATTRIBUTES.NORM = false;
            PARAMS.ATTRIBUTES.CURV = false;
            PARAMS.ATTRIBUTES.COLOR = true;

            PARAMS.ESTIMATOR_TYPE = {'VAR'};
            PARAMS.POOLING_TYPE = {'Mean'};
            PARAMS.NEIGHBORHOOD_SIZE = 12;
            PARAMS.CONST = eps(1);
            PARAMS.REF = 0;
        else
           error('Configure PARAMS.');
        end
    else
        if PARAMS.ATTRIBUTES.NORM && (~isfield(sA,'norm') || ~isfield(sB,'norm'))
            error('No normals found in input point cloud(s).');
        end
        if PARAMS.ATTRIBUTES.CURV && (~isfield(sA,'curv') || ~isfield(sB,'curv'))
            error('No curvatures found in input point cloud(s).');
        end
        if PARAMS.ATTRIBUTES.COLOR && (~isfield(sA,'color') || ~isfield(sB,'color'))
            error('No color found in input point cloud(s).');
        end
    end
end


%% Conversion to double
A = structfun(@double, sA, 'UniformOutput', false);
B = structfun(@double, sB, 'UniformOutput', false);


%% Sort geometry and corresponding attributes
[A.geom, idgA] = sortrows(A.geom);
[B.geom, idgB] = sortrows(B.geom);
if PARAMS.ATTRIBUTES.NORM
    A.norm = A.norm(idgA, :);
    B.norm = B.norm(idgB, :);
end
if PARAMS.ATTRIBUTES.CURV
    A.curv = A.curv(idgA, :);
    B.curv = B.curv(idgB, :);
end
if PARAMS.ATTRIBUTES.COLOR
    A.color = A.color(idgA, :);
    B.color = B.color(idgB, :);
end


%% Formulation of neighborhoods in point clouds A and B
[idA, distA] = knnsearch(A.geom, A.geom, 'K', PARAMS.NEIGHBORHOOD_SIZE);
[idB, distB] = knnsearch(B.geom, B.geom, 'K', PARAMS.NEIGHBORHOOD_SIZE);


%% Association of neighborhoods between point clouds A and B
% Loop over B and find nearest neighbor in A (set A as the reference)
[idBA, ~] = knnsearch(A.geom, B.geom);
% Loop over A and find nearest neighbor in B (set B as the reference)
[idAB, ~] = knnsearch(B.geom, A.geom);


%% Structural similarity scores based on geometry-related features
if PARAMS.ATTRIBUTES.GEOM
    % Quantities as distances between a point and each neighbor
    geomQuantA = distA(:, 2:end);
    geomQuantB = distB(:, 2:end);

    % Structural similarity score(s)
    [pssim.geomBA, pssim.geomAB, pssim.geomSym] = ssim_score(geomQuantA, geomQuantB, idBA, idAB, PARAMS);

    fprintf('Structural similarity scores based on geometry-related features\n');
end


%% Structural similarity scores based on normal-related features
if PARAMS.ATTRIBUTES.NORM 
    % Quantities as normal similarities between a point and each neighbor
    nsA = real( 1 - 2*acos(abs(sum(A.norm(idA,:).*repmat(A.norm,[PARAMS.NEIGHBORHOOD_SIZE,1]), 2)./(sqrt(sum(A.norm(idA,:).^2,2)).*sqrt(sum(repmat(A.norm,[PARAMS.NEIGHBORHOOD_SIZE,1]).^2,2)))))/pi );
    normQuantA = reshape(nsA, [size(nsA,1)/PARAMS.NEIGHBORHOOD_SIZE, PARAMS.NEIGHBORHOOD_SIZE]);
    nsB = real( 1 - 2*acos(abs(sum(B.norm(idB,:).*repmat(B.norm,[PARAMS.NEIGHBORHOOD_SIZE,1]), 2)./(sqrt(sum(B.norm(idB,:).^2,2)).*sqrt(sum(repmat(B.norm,[PARAMS.NEIGHBORHOOD_SIZE,1]).^2,2)))))/pi );
    normQuantB = reshape(nsB, [size(nsB,1)/PARAMS.NEIGHBORHOOD_SIZE, PARAMS.NEIGHBORHOOD_SIZE]);
    normQuantA(:,1) = [];
    normQuantB(:,1) = [];

    % Structural similarity score(s)
    [pssim.normBA, pssim.normAB, pssim.normSym] = ssim_score(normQuantA, normQuantB, idBA, idAB, PARAMS);

    fprintf('Structural similarity scores based on normal-related features\n');
end


%% Structural similarity scores based on curvature-related features
if PARAMS.ATTRIBUTES.CURV 
    % Quantities as curvature of points that belong to the neighborhood
    curvQuantA = real(A.curv(idA));
    curvQuantB = real(B.curv(idB));

    % Structural similarity score(s)
    [pssim.curvBA, pssim.curvAB, pssim.curvSym] = ssim_score(curvQuantA, curvQuantB, idBA, idAB, PARAMS);

    fprintf('Structural similarity scores based on curvature-related features\n');
end


%% Structural similarity scores based on color-related features
if PARAMS.ATTRIBUTES.COLOR
    % Quantities as luminance of points that belong to the neighborhood
    [yA, ~, ~] = rgb_to_yuv(A.color(:,1), A.color(:,2), A.color(:,3));
    [yB, ~, ~] = rgb_to_yuv(B.color(:,1), B.color(:,2), B.color(:,3));
    colorQuantA = double(yA(idA));
    colorQuantB = double(yB(idB));

    % Structural similarity score(s)
    [pssim.colorBA, pssim.colorAB, pssim.colorSym] = ssim_score(colorQuantA, colorQuantB, idBA, idAB, PARAMS);

    fprintf('Structural similarity scores based on color-related features\n');
end
