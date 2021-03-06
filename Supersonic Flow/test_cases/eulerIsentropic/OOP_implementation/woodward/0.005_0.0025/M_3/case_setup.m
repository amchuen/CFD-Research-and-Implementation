clc;
clear;
close all;

case_name = 'woodward';

%% Define grid_lims

dx = 0.0025;
dy = 0.005;

% Field Axis Values - body fitted grid
grid_lims = [   0+0.5*dy,  0.2-0.5*dy, dy; % y-range
                0.0, 0.6-(0.5.*dx),    dx];... 

grid_lims(:,:,2) = [    0.2+0.5.*dy-mod(0.2,dy),  1.0, dy; % y-range
                        0.0, 0.6-(0.5.*dx),    dx];... 
                        
grid_lims(:,:,3) = [    0.2+0.5.*dy-mod(0.2,dy),  1.0, dy;
                        0.6+(0.5.*dx)-mod(0.6,dx), 3.0, dx];

%% Airfoil Geometry

tau = 0.1;
x_vals = grid_lims(2,1):grid_lims(2,3):grid_lims(2,2);
YY_B = [zeros(size(x_vals(x_vals <0))), ...
        2*tau.*x_vals((x_vals>=0)&(x_vals <=1)).*(1- x_vals((x_vals>=0)&(x_vals <=1))),...
        zeros(size(x_vals(x_vals >1)))];
dyBdx = zeros(size(YY_B));

for i = 2:(length(YY_B)-1)
   dyBdx(i+1) = (YY_B(i) - YY_B(i-1))/(2*dx);
end

%% Control Params - simulation control, including tolerances, viscous factor gain, etc.

CT.eps_s = 0.00075;% 0.07525; % spatial diffusion term
CT.eps_t = 0.013;  % time diffusion term
CT.tol = 1e-4;
CT.dt = 0.1;
CT.iter_min = 300;
CT.CFL_on = 1;
CT.use_1visc = 1;
CT.is_polar = 0;
CT.case_name = 'cylinder_vec_1visc';

%% Fluid Params
FL.M0 = 3.0;
FL.gam = 1.4;

%% Boundary Condition Setup

BC_setup = {'W',        'E',        'N',            'S';...
            'inlet',    'wall',   'patch',    'wall';...
            1,          0,          1,              0;...
            1,          0,          1,              0;...
            0,          0,          0,              0};

BC_setup2 = {'W',        'E',        'N',            'S';...
            'inlet',    'patch',   'wall',    'patch';...
            1,          1,          0,              1;...
            1,          1,          0,              1;...
            0,          0,          0,              0};

BC_setup3 = {'W',        'E',        'N',            'S';...
            'patch',    'outlet',   'wall',    'wall';...
            1,          0,          0,              0;...
            1,          0,          0,              0;...
            0,          0,          0,              0};        
        
test = eulerIsentropicField(CT, grid_lims(:,:,1), FL, BC_setup);
test(2) = eulerIsentropicField(CT, grid_lims(:,:,2), FL, BC_setup2);
test(3) = eulerIsentropicField(CT, grid_lims(:,:,3), FL, BC_setup3);
tic;
while test.checkConvergence
    test = test.timeStep_tl;
    test = test.updateVals;
    
end

%% Post Process
folderName = ['M_' num2str(FL.M0)];
geomName = [case_name];
sizeName = [num2str(test(1).GR.d1) '_' num2str(test(1).GR.d2)];
dirName = [pwd '\' geomName '\' sizeName '\' folderName];


if ~exist(dirName, 'dir')
    mkdir(dirName);
end

% cd([pwd '\' geomName '\' folderName]);
test.post_process(dirName);

copyfile('woodward_test.m',[dirName '\case_setup.m']);

% cd('../../');

% XX = cat(1, test(1).GR.XX, test(2).GR.XX);
% YY = cat(1, test(1).GR.YY, test(2).GR.YY);
% UU = cat(1, test(1).FV(1).fv(:,:,2,3) ./ test(1).FV(1).fv(:,:,1,3), test(2).FV(1).fv(:,:,2,3) ./ test(2).FV(1).fv(:,:,1,3));
% figure();contourf(XX, YY, UU, 50);