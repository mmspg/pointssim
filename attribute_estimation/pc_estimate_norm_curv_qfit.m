function [normals, curvatures] = pc_estimate_norm_curv_qfit(pcIn, SEARCH_METHOD, SEARCH_SIZE)
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
% Estimation of normals and curvatures of a point cloud using quadric 
%   fitting. The neighbors required around every point for the fitting 
%   process can be identified using either k-nn or range-search algorithms. 
%   Moreover, the size of the neighborhood can be determined.
%  
%   [normals, curvatures] = pc_estimate_norm_curv_qfit(pcIn, SEARCH_METHOD, SEARCH_SIZE)
%
%   INPUTS
%       pcIn: A pointCloud object, or path to file. The size of 
%           pcIn.Location is Nx3, with N the number of points.
%       SEARCH_METHOD: Selected method to identify neighborhoods for the
%           fitting process, with available options: {'rs', 'knn'}. The
%           first corresponds to range-search while the second to k-nn.
%       SEARCH_SIZE: Size of neighborhoods for the fitting process. When 
%           SEARCH_METHOD is set to 'rs', the SEARCH_SIZE corresponds to
%           the radius. When SEARCH_METHOD is set to 'knn', the SEARCH_SIZE
%           corresponds to the k neighbors.
%           
%   OUTPUTS
%       normals: Normal vectors. The size is Nx3.
%       curvatures: Curvature values. The size is Nx1.


if nargin < 1
    error('Too few input arguments.');
else
    if(any(ischar(pcIn)))
        pc = pcread(pcIn);
    elseif(isa(pcIn,'pointCloud'))
        pc = pcIn;
    end
    
    if nargin == 1
        SEARCH_METHOD = 'rs';
        SEARCH_SIZE = round(0.01 * double(max(max(pc.Location) - min(pc.Location))));
    else
        switch SEARCH_METHOD
            case {'knn', 'rs'}
            otherwise
                error('SEARCH_METHOD is not supported.');
        end
        if SEARCH_SIZE <= 0
            error('SEARCH_SIZE should be non-negative.');
        end
    end
end


fprintf('Normals and curvatures estimation\n');
geom = double(pc.Location);

fprintf('\tNeighborhoods formulation\n');
tic;
if strcmp(SEARCH_METHOD, 'rs')
    [id, ~] = rangesearch(geom, geom, SEARCH_SIZE);
elseif strcmp(SEARCH_METHOD, 'knn')
    [id, ~] = knnsearch(geom, geom, 'k', SEARCH_SIZE);
end
toc;

fprintf('\tComputing\n');
tic;
normals = nan(size(geom,1),3);
curvatures = nan(size(geom,1),1);
for i = 1:size(geom,1)
% parfor i = 1:size(geom,1)
    
    point = geom(i,:);
    if strcmp(SEARCH_METHOD, 'rs')
        point_neighb = geom(id{i},:);
    else
        point_neighb = geom(id(i,:),:);
    end

    covariance_matrix = cov(point_neighb,1);
    if sum(isnan(covariance_matrix(:))) > 1
        continue;
    end
    
    [eigvecs, ~] = pcacov(covariance_matrix);
    if size(eigvecs,2) ~= 3
        continue;
    end
    
    % Project data onto the new orthonormal basis
    data_transf = (point_neighb - mean(point_neighb))*eigvecs;
    point_transf = (point - mean(point_neighb))*eigvecs;

    % Translate data to origin [0,0,0]
    xyz = data_transf - point_transf;

    % Fit polynomial surface
    p = polyfitn_c([xyz(:,1), xyz(:,2)], xyz(:,3), 2);
    if isnan(p.Coefficients)
        continue;
    end
    
    % Get coefficients
    p20 = p.Coefficients(1);
    p11 = p.Coefficients(2);
    p10 = p.Coefficients(3);
    p02 = p.Coefficients(4);
    p01 = p.Coefficients(5);
%     p00 = p.Coefficients(6);
    
    % Compute gradients
    grad_x = p10;
    grad_y = p01;
    
    % Compute normal on the new orthonormal basis
    normal = [-grad_x, -grad_y, 1];
    normal = normal./norm(normal);
    
    % Inverse transform to the original orthonormal basis
    normal = normal*eigvecs';
    
    % Return normal and curvature estimates based on quadric fitting
    normals(i,:) = normal./norm(normal);
    curvatures(i) = ((1+p10^2)*p20 + (1+p01^2)*p02 - 4*p20*p02*p11) / (1 + p01^2 + p10^2)^(3/2);
end
toc;
