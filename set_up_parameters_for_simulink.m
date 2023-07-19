%% Path
mydir  = pwd;
addpath(genpath([pwd, filesep, 'file_mat']))
addpath(genpath([pwd, filesep, 'support']))

%% General parameters
T_sim = 1e-2; % Simulation time (and sampling time) [s]
T_amb = 15; % Ambient temperature
T_PWM_1 = 1; % Period of the SSRs [s]
T_PWM_2 = 30; % Period of the EMRs [s]

simulink_name_ol = 'complete_model_ol';
simulink_name_cl = 'complete_model_cl';

%% General imports and definitions
load('success_rates_packs_temperatures.mat')
load('T_d_heat_temperatures.mat')

rng(1)
% Bernoulli distribution (not compatible with Simulink)
% 30PPM
% pd30PPM = makedist('Binomial','N',1,'p',success_rates_packs_temperatures(1));
% 60PPM
% pd60PPM = makedist('Binomial','N',1,'p',success_rates_packs_temperatures(2));
% 90PPM
% pd90PPM = makedist('Binomial','N',1,'p',success_rates_packs_temperatures(3));

%% User defined parameters and imports
if not(exist('T_c', 'var'))
    error('You must define the control time T_c')
end

if not(exist('simulink_type', 'var'))
    error('You must define simulink_type, either ''ol'' or ''cl''')
end

if T_c == T_PWM_1
    duty_cycle_allocation_name = 'duty_cycle_allocation_T_PWM_1';
elseif floor(T_c/T_PWM_2) == T_c/T_PWM_2
    duty_cycle_allocation_name = 'duty_cycle_allocation_mT_PWM_2';
else
    error('Wrong choice of T_c. T_c must be either be 1 or a multiple of 30')
end

p = 12; % Number of outputs
heat_temperatures_model_name = 'heat_temperatures_12';
packs_temperatures_model_name = 'packs_temperatures_12';
load('ss_heat_temperatures_12.mat')
load('params_packs_temperatures_12.mat')

switch simulink_type
    case 'ol'
        simulink_name = simulink_name_ol;
    case 'cl'
        simulink_name = simulink_name_cl;
    otherwise
        error('Wrong choice of simulink_type. simulink_type must be either ''ol'' or ''cl''')
end

%% Open Simulink and set subsystems
open([simulink_name, '.slx'])
set_param([simulink_name, '/Plant/Heat-Temperatures model'], ...
    'ReferencedSubsystem', heat_temperatures_model_name);
set_param([simulink_name, '/Plant/Packs-Temperatures model'], ...
    'ReferencedSubsystem', packs_temperatures_model_name);
set_param([simulink_name, '/PWM_Generation'], ...
    'ReferencedSubsystem', 'PWM_generation');
set_param([simulink_name, '/Duty cycle allocation'], ...
    'ReferencedSubsystem', duty_cycle_allocation_name);