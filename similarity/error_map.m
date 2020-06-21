function [eMapYX] = error_map(fMapY, fMapX, idYX, CONST)
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
% Error map of point cloud Y, based on the relative difference between
%   associated feature maps of X and Y.
%
%   [eMapYX] = error_map(fMapY, fMapX, idYX, CONST)
%
%   INPUTS
%       fMapX: Feature map of point cloud X. The size is Nx1
%       fMapY: Feature map of point cloud Y. The size is Mx1
%       idYX: Indices for the nearest points of Y in X. The size is Mx1
%       CONST: Defines a constant that is included in the relative
%           difference computation to avoid undefined operations
%
%   OUTPUTS
%       eMapYX: Error map of point cloud Y, using X as reference. The size
%           is Mx1, with M the number of points of Y


eMapYX = abs(fMapX(idYX) - fMapY)./(max([abs(fMapX(idYX)), abs(fMapY)], [], 2) + CONST);
