function [pcOut] = pc_vox_scale(pcIn, voxIn, voxOut)
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
% Voxelization of a point cloud at a different bit-depth. The script
%   handles only voxelized inputs with (optional) color attributes. The
%   output voxels will be scaled through an affine transformation that
%   mantains the ratios of lengths of parallel segments. After the scaling
%   process, points with the same coordinates are pruned, and their
%   corresponding color values are blended.
%
%   [pcOut] = pc_vox_scale(pcIn, voxIn, voxOut)
%
%   INPUTS
%       pcIn: Voxelized pointCloud object, or path to file.
%       voxIn: The voxel bit-depth of the input point cloud.
%       voxOut: The voxel bit-depth of the output point cloud.
%
%   OUTPUTS
%       pcOut: Voxelized point cloud at the target, output bit-depth.


if nargin < 3
    error('Too few input arguments.');
else
    if(any(ischar(pcIn)))
        pc = pcread(pcIn);
    elseif(isa(pcIn,'pointCloud'))
        pc = pcIn;
    end
end

% Get geometry and color
geomIn = double(pc.Location);
clrsIn = double(pc.Color);

% If not current voxel depth is given, get an estimate
if isempty(voxIn)
    % Ceil of the range minus an offset, to avoid cases where the codec
    % fails to reach the exact grid (i.e., 1026 instead of 1023)
    offset = 10;
    voxIn = ceil(log2(max([max(geomIn) - min(geomIn)]) - offset));
end

% Quantization step
quantStep = 1 / (2^voxOut - 1);

% The output voxels mantain the ratios of lengths of parallel segments. No
% clipping is applied
geomIn = geomIn./(2^voxIn - 1);
quantGeom = floor(geomIn/quantStep + 1/2);

% Sort quantized geometry (first sort last column, then second, then first)
[quantGeomSorted, col] = sortrows(quantGeom);

% Sort color attributes accordingly
clrsSorted = clrsIn(col, :);

% Find indexes of points with different quantized geometry
d = diff(quantGeomSorted,1,1);
sd = sum(abs(d),2) > 0;
id = [1; find(sd == 1)+1; size(quantGeomSorted,1)+1];

% Average color of points with same quantized geometry
clrsBlend = zeros(size(id,1)-1,3);
for j = 1:size(id,1)-1
    clrsBlend(j,:) = mean(clrsSorted(id(j):id(j+1)-1, :), 1);
end

% Remove threshold index
id(end) = [];

% Voxel coordinates as unique quantized geometry
geomOut = single(quantGeomSorted(id,:));

% Voxel colors as blend of colors of points with same quantized geometry
clrOut = uint8(round(clrsBlend));

% Point cloud voxelized at the voxTarget
pcOut = pointCloud(geomOut, 'Color', clrOut);
