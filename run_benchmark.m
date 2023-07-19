%% Setup
clc
clear
close all

% Choose the execution time of your controller
% Either 1 or a multiple of 30
T_c = 1; % [s]
simulink_type = 'cl';

set_up_parameters_for_simulink

% Reference your controller in Simulink
your_controller_name = 'PI_original';
set_param([simulink_name, '/Controller/Your_controller'], ...
    'ReferencedSubsystem', your_controller_name);
% Run the script which sets the parameters of your controller
PI_original_parameters

%% Signal generation
trial_length = 28000; % [s]
times = (0 : T_sim :  trial_length)'; % [s]
N = length(times);

% Grid voltage
V_grid = zeros(N, 1);
for i = 1 : N
    V_grid(i,1) = randi([380 410], 1, 1);
    
end
V_grid_filter = designfilt('lowpassiir','FilterOrder',2, ...
    'HalfPowerFrequency',0.05,'DesignMethod','butter');

V_grid = filtfilt(V_grid_filter, V_grid);
V_grid = timeseries(V_grid, times);

% Production rate
v = zeros(N, 1);
v(350000:500000) = 60;
v(500000:700000) = 30;
v(700000:750000) = 0;
v(800000:1100000) = 90;
v(1100000:1300000) = 30;
v(1300000:1350000) = 0;
v(1500000:1800000) = 60;
v(1800000:2100000) = 90;
v(2100000:2150000) = 90;
v(2150000:2300000) = 30;
v(2300000:2500000) = 60;
v(2500000:2700000) = 30;
v = timeseries(v, times);

% Setpoint
SP = 160*ones(N, 1);
SP = timeseries(SP, times);

%% Simulation
set_param(simulink_name, 'Solver', 'ode45', ...
    'StartTime', num2str(times(1)), ...
    'StopTime', num2str(times(end)))

out = sim(simulink_name, 'ReturnWorkspaceOutputs', 'on');

%% Plotting - setup
plot_order = {[1, 2], [7, 8], [3, 4], [9, 10], [5, 6], [11, 12]};
temperature_lcs = {'$T_1^{(3, r)}$', ...
    '$T_1^{(3, l)}$', ...
    '$T_1^{(2, r)}$', ...
    '$T_1^{(2, l)}$', ...
    '$T_1^{(1, r)}$', ...
    '$T_1^{(1, l)}$', ...
    '$T_2^{(1, r)}$', ...
    '$T_2^{(1, l)}$', ...
    '$T_2^{(2, r)}$', ...
    '$T_2^{(2, l)}$', ...
    '$T_1^{(3, r)}$', ...
    '$T_1^{(3, l)}$'};

full_names = cell(p, 1);
for i = 1 : p
    full_names{i} = ['$y_{', num2str(i), '}$ - ', temperature_lcs{i}];
end

linewidth = 2;
fontSize = 18;
color_zone_1 = 'b';
color_zone_1_2 = 'c';
color_zone_2 = 'r';
color_zone_2_2 = [0.8500 0.3250 0.0980];
color_packs = 'g';
color_grid_voltage_and_production_rate = 'k';
sp_linespec = 'm :';

set(0, 'defaultAxesFontSize', fontSize);
set(0, 'defaultAxesTickLabelInterpreter', 'latex');

temperature_lims = [0 200];
temperature_ticks = 0 : 25 : 200;
duty_lims = [0 1];
duty_ticks = 0 : 0.25 : 1;
production_rate_lims = [0 200];
production_rate_ticks = [0, 30, 60, 90];
V_grid_lims = [0, 410];
V_grid_ticks = 0 : 100 : 400;

%% Temperatures
figure
tiledlayout(length(plot_order)/2 + 1, 2, 'TileSpacing', 'compact')
axes = [];
% Downsample signals for plotting purposes (less demanding)
for i = 1 : length(plot_order)
    axes = [axes, nexttile];
    
    if plot_order{i}(1) > p/2
        curr_color_1 = color_zone_2;
        curr_color_2 = color_zone_2_2;
    else
        curr_color_1 = color_zone_1;
        curr_color_2 = color_zone_1_2;
    end
    yyaxis left
    plot(downsample(out.y.Time/60, 100), ...
        downsample(out.y.Data(:, plot_order{i}(1)), 100), ...
        curr_color_1, 'linewidth', linewidth)
    hold on
    plot(downsample(out.y.Time/60, 100), ...
        downsample(out.y.Data(:, plot_order{i}(2)), 100), ...
        '--', 'Color', curr_color_2, 'linewidth', linewidth)
    plot(downsample(SP.Time/60, 100), ...
        downsample(SP.Data, 100), ...
        sp_linespec, 'linewidth', linewidth)
    visualizePacksFlow(downsample(out.d.Data, 100), ...
        downsample(out.d.Time/60, 100), ...
        temperature_lims, color_packs)
    grid on
    ylim(temperature_lims)
    yticks(temperature_ticks)
    ylabel('$y_k(t)$ $\left[^\circ C\right]$', 'interpreter', 'latex')
    xlabel('')
    
    yyaxis right
    plot(downsample(v.Time/60, 100), ...
        downsample(v.Data, 100), ...
        color_grid_voltage_and_production_rate, 'linewidth', linewidth)
    ylabel('$v(t)$ $\left[ppm\right]$', 'interpreter', 'latex')
    ylim(production_rate_lims)
    yticks(production_rate_ticks)
    
    xlim([min(times/60), max(times/60)])
    
    legend({['$y_{', num2str(plot_order{i}(1)), '}(t)$ - ' temperature_lcs{plot_order{i}(1)}], ...
        ['$y_{', num2str(plot_order{i}(2)), '}(t)$ - ' temperature_lcs{plot_order{i}(2)}]}, ...
        'interpreter', 'latex', ...
        'location', 'southwest')
    
    ax = gca;
    ax.YAxis(1).Color = curr_color_1;
    ax.YAxis(2).Color = color_grid_voltage_and_production_rate;
    
    yyaxis left
end

axes = [axes, nexttile];
yyaxis left
plot(downsample(out.w_1.Time/60, 100), ...
    downsample(out.w_1.Data, 100), ...
    color_zone_1, 'linewidth', linewidth)
grid on
ylim(duty_lims)
yticks(duty_ticks)
ylabel('$w_1(t)$', 'interpreter', 'latex')
xlabel('$t \left[min\right]$', 'interpreter', 'latex')

yyaxis right
plot(downsample(V_grid.Time/60, 100), ...
    downsample(V_grid.Data, 100), ...
    color_grid_voltage_and_production_rate, 'linewidth', linewidth)
ylabel('$V_{grid}(t)$ $\left[V\right]$', 'interpreter', 'latex')
ylim(V_grid_lims)
yticks(V_grid_ticks)

xlim([min(times/60), max(times/60)])

yyaxis left

ax = gca;
ax.YAxis(1).Color = color_zone_1;
ax.YAxis(2).Color = color_grid_voltage_and_production_rate;

axes = [axes, nexttile];
yyaxis left
plot(downsample(out.w_2.Time/60, 100), ...
    downsample(out.w_2.Data, 100), ...
    color_zone_2, 'linewidth', linewidth)
grid on
ylim(duty_lims)
yticks(duty_ticks)
ylabel('$w_2(t)$', 'interpreter', 'latex')
xlabel('$t \left[min\right]$', 'interpreter', 'latex')

yyaxis right
plot(downsample(V_grid.Time/60, 100), ...
    downsample(V_grid.Data, 100), ...
    color_grid_voltage_and_production_rate, 'linewidth', linewidth)
ylabel('$V_{grid}(t)$ $\left[V\right]$', 'interpreter', 'latex')
ylim(V_grid_lims)
yticks(V_grid_ticks)

xlim([min(times/60), max(times/60)])

ax = gca;
ax.YAxis(1).Color = color_zone_2;
ax.YAxis(2).Color = color_grid_voltage_and_production_rate;

yyaxis left

linkaxes(axes, 'x')

%% Performance indicators
%% Setpoint tracking
id_start_SP_tracking = 1;
id_end_SP_tracking = find(v.Data > 0, 1, 'first');

SP_SP_tracking = SP.Data(id_start_SP_tracking : id_end_SP_tracking);
times_SP_tracking = times(id_start_SP_tracking : id_end_SP_tracking);
y_SP_tracking = cell(p, 1);
for i = 1 : p
    y_SP_tracking{i} = out.y.Data(id_start_SP_tracking : id_end_SP_tracking, i);
end

stepInfos = cell(p, 1);
steady_state_errors = nan(p, 1);
settling_times = nan(p, 1);
for i = 1 : p
    stepInfos{i} = stepinfo(y_SP_tracking{i}, times_SP_tracking);
    settling_times(i) = stepInfos{i}.SettlingTime;
    fprintf('y_%d settling_time = %.2f [min] \n', ...
        i, settling_times(i)/60);
    
    steady_state_errors(i) = abs(SP_SP_tracking(end) - y_SP_tracking{i}(end));
    fprintf('y_%d steady_state_error  = %.2f [°C] \n\n',...
        i, steady_state_errors(i));
end

figure
tiledlayout(2, 1, 'TileSpacing', 'compact')
nexttile
bar(1 : 1 : p/2, settling_times(1 : p/2)/60, color_zone_1)
hold on
bar(p/2 + 1 : 1 : p, settling_times(p/2 + 1 : 1 : p)/60, color_zone_2)
xticks(1 : 1 : p)
xticklabels(full_names)
ylabel('Settling time $[min]$', 'interpreter', 'latex')

nexttile
bar(1 : 1 : p/2, steady_state_errors(1 : p/2), color_zone_1)
hold on
bar(p/2 + 1 : 1 : p, steady_state_errors(p/2 + 1 : 1 : p), color_zone_2)
xticks(1 : 1 : p)
xticklabels(full_names)
ylabel('Steady state errors $[^\circ C]$', 'interpreter', 'latex')

%% Disturbance rejection
id_start_production = find(v.Data > 0, 1, 'first');
id_end_production = find(v.Data > 0, 1, 'last');

times_d_rejection = times(id_start_production : id_end_production);
d_d_rejection = out.d.Data(id_start_production : id_end_production);
y_d_rejection = cell(p, 1);
for i = 1 : p
    y_d_rejection{i} = out.y.Data(id_start_production : id_end_production, i);
end

AUC = nan(p, 1);
y_err = cell(p, 1);
for i = 1 : p
    y_err{i} = y_d_rejection{i} - y_d_rejection{i}(1);
    AUC(i) = trapz(times_d_rejection./60, abs(y_err{i}));
    fprintf('y_%d AUC = %.2f [°C/min] \n', i, AUC(i));
end
fprintf('\n');


ylims = [-30 30];
alpha = 0.6;
figure
tiledlayout(length(plot_order)/2, 2, 'TileSpacing', 'compact')
axes = [];
% Downsample signals for plotting purposes (less demanding)
for i = 1 : length(plot_order)
    axes = [axes, nexttile];
    
    if plot_order{i}(1) > p/2
        curr_color_1 = color_zone_2;
        curr_color_2 = color_zone_2_2;
    else
        curr_color_1 = color_zone_1;
        curr_color_2 = color_zone_1_2;
    end
    
    plot(downsample(times_d_rejection/60, 100), ...
        downsample(y_err{plot_order{i}(1)}, 100), ...
        curr_color_1, 'linewidth', linewidth)
    hold on
    plot(downsample(times_d_rejection/60, 100), ...
        downsample(y_err{plot_order{i}(2)}, 100), ...
        '--', 'Color', curr_color_2, 'linewidth', linewidth)
    area(times_d_rejection/60, y_err{plot_order{i}(1)}, ...
        'linewidth', linewidth, ...
        'FaceColor', curr_color_1);
    area(times_d_rejection/60, y_err{plot_order{i}(2)}, ...
        'linewidth', linewidth, ...
        'FaceColor', curr_color_2);
    visualizePacksFlow(downsample(d_d_rejection, 100), ...
        downsample(times_d_rejection/60, 100), ...
        ylims, color_packs)
    grid on
    ylim(ylims)
    ylabel('$y_k(t) - \bar{y}_k''$ $\left[^\circ C\right]$', 'interpreter', 'latex')
    xlabel('')
    
    xlim([min(times/60), max(times/60)])
    
    legend({['$y_{', num2str(plot_order{i}(1)), '}(t)$ - ' temperature_lcs{plot_order{i}(1)}], ...
        ['$y_{', num2str(plot_order{i}(2)), '}(t)$ - ' temperature_lcs{plot_order{i}(2)}]}, ...
        'interpreter', 'latex', ...
        'location', 'southwest')
    
    if i == length(plot_order) - 1 || ...
            i == length(plot_order)
        xlabel('$t \left[min\right]$', 'interpreter', 'latex')
    end
end

%% Energy saving
R_heat = 1239; % Ohm

V_1_1 = out.V.V_1_1.Data;
V_1_2 = out.V.V_1_2.Data;
V_2_1 = out.V.V_2_1.Data;
V_2_2 = out.V.V_2_2.Data;

E_V = trapz(times, (V_1_1.^2)/R_heat) + ...
    trapz(times, (V_1_2.^2)/R_heat) + ...
    trapz(times,(V_2_1.^2)/R_heat) + ...
    trapz(times,(V_2_2.^2)/R_heat);
% Conversion from Joule to Wh
E_V = E_V/(3600);

fprintf('Energy consumption E_V = %.2f [Wh] \n', E_V);
