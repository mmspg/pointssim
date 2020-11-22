function [pointssim] = pc_ssim(pcA, pcB, PARAMS)
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
%   represented by the corresponding custom structs pcA and pcB. Local 
%   neighborhoods are formulated in A and B, and then they are associated. 
%   In each local neighborhood, per-attribute quantities are defined. For 
%   each point cloud, a feature map is extracted using a statistical 
%   dispersion estimator on these per-attribute quantities. An error map is  
%   obtained as the relative difference between associated feature maps,  
%   and a structural similarity score is computed through pooling. A 
%   structural similarity score is obtained per attribute, and depends on  
%   the dispersion estimator, the pooling method, the size of the local 
%   neighborhood, and the selection of the reference point cloud. These 
%   parameters can be configured in the struct PARAMS.
%
%   [pointssim] = pc_ssim(pcA, pcB, PARAMS)
%
%   INPUTS
%       pcA: Custom struct for point cloud A, with fields:
%           geom - Geometry (mandatory field). 
%               The size is Nx3, with N the number of points of A.
%           norm - Normal vectors (optional field). 
%               The size is Nx3, with N the number of points of A.
%           curv - Curvature values (optional field). 
%               The size is Nx1, with N the number of points of A.
%           color - RGB color values (optional field). 
%               The size is Nx3, with N the number of points of A.
%       pcB: Custom struct for point cloud B, with fields:
%           geom - Geometry (mandatory field). 
%               The size is Mx3, with M the number of points of B.
%           norm - Normal vectors (optional field). 
%               The size is Mx3, with M the number of points of B.
%           curv - Curvature values (optional field).
%               The size is Mx1, with M the number of points of B.
%           color - RGB color values (optional field). 
%               The size is Mx3, with M the number of points of B.
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
%               {'Variance', 'Median', 'MeanAD', 'MedianAD', 'COV', 'QCD'}.
%               More than one options can be enabled.
%           POOLING_TYPE - Defines the pooling method(s) that will be used  
%               to compute a total quality score, with available options: 
%               {'Mean', 'Min', 'Max', 'MSE', 'RMS'}.
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
%       pointssim: Structural similarity scores for different ATTRIBUTES,
%           ESTIMATOR_TYPE, and POOLING_TYPE, depending on the PARAMS.


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
        PARAMS.POOLING_TYPE = {'Mean', 'Max', 'MSE', 'RMS'};
        PARAMS.NEIGHBORHOOD_SIZE = 12;
        PARAMS.CONST = eps(1);
        PARAMS.REF = 0;
    end
end



%% Conversion to double
A = structfun(@double, pcA, 'UniformOutput', false);
B = structfun(@double, pcB, 'UniformOutput', false);


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
    [pointssim.geomBA, pointssim.geomAB, pointssim.geomSym] = ssim_score(geomQuantA, geomQuantB, idBA, idAB, PARAMS);

    fprintf('Structural similarity scores based on geometry-related features\n');
end


%% Structural similarity scores based on normal-related features
if PARAMS.ATTRIBUTES.NORM && ~isempty(A.norm) && ~isempty(B.norm)
    % Quantities as normal similarities between a point and each neighbor
    nsA = real( 1 - 2*acos(abs(sum(A.norm(idA,:).*repmat(A.norm,[PARAMS.NEIGHBORHOOD_SIZE,1]), 2)./(sqrt(sum(A.norm(idA,:).^2,2)).*sqrt(sum(repmat(A.norm,[PARAMS.NEIGHBORHOOD_SIZE,1]).^2,2)))))/pi );
    normQuantA = reshape(nsA, [size(nsA,1)/PARAMS.NEIGHBORHOOD_SIZE, PARAMS.NEIGHBORHOOD_SIZE]);
    nsB = real( 1 - 2*acos(abs(sum(B.norm(idB,:).*repmat(B.norm,[PARAMS.NEIGHBORHOOD_SIZE,1]), 2)./(sqrt(sum(B.norm(idB,:).^2,2)).*sqrt(sum(repmat(B.norm,[PARAMS.NEIGHBORHOOD_SIZE,1]).^2,2)))))/pi );
    normQuantB = reshape(nsB, [size(nsB,1)/PARAMS.NEIGHBORHOOD_SIZE, PARAMS.NEIGHBORHOOD_SIZE]);
    normQuantA(:,1) = [];
    normQuantB(:,1) = [];

    % Structural similarity score(s)
    [pointssim.normBA, pointssim.normAB, pointssim.normSym] = ssim_score(normQuantA, normQuantB, idBA, idAB, PARAMS);

    fprintf('Structural similarity scores based on normal-related features\n');
end


%% Structural similarity scores based on curvature-related features
if PARAMS.ATTRIBUTES.CURV && ~isempty(A.curv) && ~isempty(B.curv)
    % Quantities as curvature of points that belong to the neighborhood
    curvQuantA = real(A.curv(idA));
    curvQuantB = real(B.curv(idB));

    % Structural similarity score(s)
    [pointssim.curvBA, pointssim.curvAB, pointssim.curvSym] = ssim_score(curvQuantA, curvQuantB, idBA, idAB, PARAMS);

    fprintf('Structural similarity scores based on curvature-related features\n');
end


%% Structural similarity scores based on color-related features
if PARAMS.ATTRIBUTES.COLOR && ~isempty(A.color) && ~isempty(B.color)
    % Quantities as luminance of points that belong to the neighborhood
    [yA, ~, ~] = rgb_to_yuv(A.color(:,1), A.color(:,2), A.color(:,3));
    [yB, ~, ~] = rgb_to_yuv(B.color(:,1), B.color(:,2), B.color(:,3));
    colorQuantA = double(yA(idA));
    colorQuantB = double(yB(idB));

    % Structural similarity score(s)
    [pointssim.colorBA, pointssim.colorAB, pointssim.colorSym] = ssim_score(colorQuantA, colorQuantB, idBA, idAB, PARAMS);

    fprintf('Structural similarity scores based on color-related features\n');
end
