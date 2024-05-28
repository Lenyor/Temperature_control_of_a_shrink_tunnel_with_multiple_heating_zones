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
V_g = 380 * ones(N, 1);
V_g = timeseries(V_g, times);

% Duty cycles
u_1 = 0.7 * ones(N, 1);
u_1 = timeseries(u_1, times);
u_2 = 0.7 * ones(N, 1);
u_2 = timeseries(u_2, times);

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

warning('off', 'Simulink:blocks:SwitchIgnoringThreshold')
out = sim(simulink_name, 'ReturnWorkspaceOutputs', 'on');
warning('on', 'Simulink:blocks:SwitchIgnoringThreshold')

%% Plotting - setup
plot_order = {[1, 2], [7, 8], [3, 4], [9, 10], [5, 6], [11, 12]};
temperature_lcs = {'$y_1^{(3, \mathrm{r})}$', ...
    '$y_1^{(3, \mathrm{l})}$', ...
    '$y_1^{(2, \mathrm{r})}$', ...
    '$y_1^{(2, \mathrm{l})}$', ...
    '$y_1^{(1, \mathrm{r})}$', ...
    '$y_1^{(1, \mathrm{l})}$', ...
    '$y_2^{(1, \mathrm{r})}$', ...
    '$y_2^{(1, \mathrm{l})}$', ...
    '$y_2^{(2, \mathrm{r})}$', ...
    '$y_2^{(2, \mathrm{l})}$', ...
    '$y_2^{(3, \mathrm{r})}$', ...
    '$y_2^{(3, \mathrm{l})}$'};

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

temperature_lims = [0 180];
temperature_ticks = 0 : 30 : 180;
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
    ylabel('$y_i^{(l, s)}(t)$ $\left[^\circ \mathrm{C}\right]$', 'interpreter', 'latex')
    xlabel('')
    
    yyaxis right
    plot(downsample(v.Time/60, 100), ...
        downsample(v.Data, 100), ...
        color_grid_voltage_and_production_rate, 'linewidth', linewidth)
    ylabel('$v(t)$ $\left[\mathrm{ppm}\right]$', 'interpreter', 'latex')
    ylim(production_rate_lims)
    yticks(production_rate_ticks)
    
    xlim([min(times/60), max(times/60)])
    
    legend({temperature_lcs{plot_order{i}(1)}, ...
        temperature_lcs{plot_order{i}(2)}}, ...
        'interpreter', 'latex', ...
        'location', 'best', ...
        'NumColumns', 2)
    
    ax = gca;
    ax.YAxis(1).Color = curr_color_1;
    ax.YAxis(2).Color = color_grid_voltage_and_production_rate;
    
    yyaxis left
end

axes = [axes, nexttile];
yyaxis left
plot(downsample(u_1.Time/60, 100), ...
    downsample(u_1.Data, 100), ...
    color_zone_1, 'linewidth', linewidth)
grid on
ylim(duty_lims)
yticks(duty_ticks)
ylabel('$u_1(t)$', 'interpreter', 'latex')
xlabel('$t \left[\mathrm{min}\right]$', 'interpreter', 'latex')

yyaxis right
plot(downsample(V_g.Time/60, 100), ...
    downsample(V_g.Data, 100), ...
    color_grid_voltage_and_production_rate, 'linewidth', linewidth)
ylabel('$V_{\mathrm{g}}(t)$ $\left[\mathrm{V}\right]$', 'interpreter', 'latex')
ylim(V_grid_lims)
yticks(V_grid_ticks)

xlim([min(times/60), max(times/60)])

yyaxis left

ax = gca;
ax.YAxis(1).Color = color_zone_1;
ax.YAxis(2).Color = color_grid_voltage_and_production_rate;

axes = [axes, nexttile];
yyaxis left
plot(downsample(u_2.Time/60, 100), ...
    downsample(u_2.Data, 100), ...
    color_zone_2, 'linewidth', linewidth)
grid on
ylim(duty_lims)
yticks(duty_ticks)
ylabel('$u_2(t)$', 'interpreter', 'latex')
xlabel('$t \left[\mathrm{min}\right]$', 'interpreter', 'latex')

yyaxis right
plot(downsample(V_g.Time/60, 100), ...
    downsample(V_g.Data, 100), ...
    color_grid_voltage_and_production_rate, 'linewidth', linewidth)
ylabel('$V_{\mathrm{g}}(t)$ $\left[\mathrm{V}\right]$', 'interpreter', 'latex')
ylim(V_grid_lims)
yticks(V_grid_ticks)

xlim([min(times/60), max(times/60)])

ax = gca;
ax.YAxis(1).Color = color_zone_2;
ax.YAxis(2).Color = color_grid_voltage_and_production_rate;

yyaxis left

linkaxes(axes, 'x')