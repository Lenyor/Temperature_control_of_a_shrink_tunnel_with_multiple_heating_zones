%% Setup
clc
clear
close all

T_c = 1; % In practice, this is used for defining the operating mode (duty cycle allocation)
simulink_type = 'ol';

set_up_parameters_for_simulink

%% Signal generation
% Trial length [min]
trial_length = 60 * 6; % 6 hours
times = (0 : T_sim :  trial_length*60)'; % [s]
N = length(times);

% For simplicity, constant grid voltage and equal to the nominal voltage of
% the heat resistors
V_grid = 380 * ones(N, 1);
V_grid = timeseries(V_grid, times);

% Duty cycles
w_1 = 0.7 * ones(N, 1);
w_1 = timeseries(w_1, times);
w_2 = 0.7 * ones(N, 1);
w_2 = timeseries(w_2, times);

% Production rate
% First 2 hours -> 0 ppm (let the oven temperatures settle)
% 1 hour -> 30 ppm
% 1 hour -> 60 ppm
% 1 hour -> 90 ppm
% 1 hour -> 0 ppm (let the oven settle back to the original temperatures)
v = zeros(N, 1);
v((2*60*60)/T_sim + 1 : 3*60*60/T_sim) = 30;
v((3*60*60)/T_sim + 1 : 4*60*60/T_sim) = 60;
v((4*60*60)/T_sim + 1 : 5*60*60/T_sim) = 90;
v = timeseries(v, times);

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

linewidth = 2;
fontSize = 18;
color_zone_1 = 'b';
color_zone_1_2 = 'c';
color_zone_2 = 'r';
color_zone_2_2 = [0.8500 0.3250 0.0980];
color_packs = 'g';
color_grid_voltage_and_production_rate = 'k';

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
plot(downsample(w_1.Time/60, 100), ...
    downsample(w_1.Data, 100), ...
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
plot(downsample(w_2.Time/60, 100), ...
    downsample(w_2.Data, 100), ...
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