function [y, u, v] = rgb_to_yuv(r, g, b)
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
% Conversion from RGB to YUV, using ITU-R BT.709. Simplified version of:
%       "Nikola Sprljan (2020). YUV files reading and converting 
%       (https://www.mathworks.com/matlabcentral/fileexchange/36417-yuv-files-reading-and-converting), 
%       MATLAB Central File Exchange"
% 
%   [y, u, v] = rgb_to_yuv(r, g, b)
%
%   INPUTS
%       r: Red color channel
%       g: Green color channel
%       b: Blue color channel
%
%   OUTPUTS
%       y: Luminance
%       u: Blue-projection chrominance component
%       v: Red-projection chrominance component


r = double(r);
g = double(g);
b = double(b);

% Coefficients
c = [ 0.2126,  0.7152,  0.0722;
     -0.1146, -0.3854,  0.5000;
      0.5000, -0.4542, -0.0468];

% Offset
o = [0; 128; 128];

y = c(1,1)*r + c(1,2)*g + c(1,3)*b + o(1);
u = c(2,1)*r + c(2,2)*g + c(2,3)*b + o(2);
v = c(3,1)*r + c(3,2)*g + c(3,3)*b + o(3);

y = uint8(round(y));
u = uint8(round(u));
v = uint8(round(v));
