function [pcOut] = pc_fuse_points(pcIn)
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
% Fusion of points with duplicate coordinates in a point cloud.  
%   Corresponding color values (if present) are averaged, and unique 
%   coordinates are kept.
% 
%   [pcOut] = pc_fuse_points(pcIn)
%
%   INPUTS
%       pcIn: A pointCloud object, or path to file. The color values are 
%           optional. The size of pcIn.Location and the optional pcIn.Color
%           is Nx3, with N the number of points.
%
%   OUTPUTS
%       pcOut: A pointCloud object. The size of pcOut.Location and the 
%           optional pcOut.Color is Mx3, with M <= N.


if nargin < 1
    error('Too few input arguments.');
else
    if(any(ischar(pcIn)))
        pc = pcread(pcIn);
    elseif(isa(pcIn,'pointCloud'))
        pc = pcIn;
    end
end


fprintf('Point fusion\n');
tic;
% Keep unique coordinates
[geom, ind_v] = unique(double(pc.Location), 'rows');

if (size(pc.Location,1) ~= size(geom,1)) 
    warning('Duplicated points found.');
    if ~isempty(pc.Color)
        warning('Color blending is applied.');
        % Sort coordinates and corresponding color
        [geom_sorted, ind_v] = sortrows(double(pc.Location));
        color_sorted = double(pc.Color(ind_v, :));
        
        % Find indexes for different coordinates
        d = diff(geom_sorted,1,1);
        sd = sum(abs(d),2) > 0;
        id = [1; find(sd == 1)+1; size(geom_sorted,1)+1];
        
        % Average color values in points with same coordinates
        color = zeros(size(id,1)-1,3);
        for j = 1:size(id,1)-1
            color(j,:) = round(mean(color_sorted(id(j):id(j+1)-1, :), 1));
        end
        id(end) = [];
        
        % Keep corresponding geometry
        geom = geom_sorted(id,:);
    end
else
    if ~isempty(pc.Color)
        color = double(pc.Color(ind_v, :));
    end
end

% Return a pointCloud object
pcOut = pointCloud(geom);
if ~isempty(pc.Color)
    pcOut.Color = uint8(color);
end
toc;
