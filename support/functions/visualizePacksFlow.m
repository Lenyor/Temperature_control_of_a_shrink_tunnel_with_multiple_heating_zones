function visualizePacksFlow(d_signal, timeSignal, yLimits, color)
color_alpha = 0.6;

upper_curve = nan(size(d_signal));
lower_curve = nan(size(d_signal));
for i = 1 : length(d_signal)
    if d_signal(i) == 1
        upper_curve(i) = yLimits(2);
        lower_curve(i) = yLimits(1);
    else
        upper_curve(i) = 0;
        lower_curve(i) = 0;
    end
end

hold on
fill([timeSignal' fliplr(timeSignal')], ...
    [lower_curve' fliplr(upper_curve')], ...
    color, ...
    'EdgeColor', 'none', ...
    'FaceAlpha', color_alpha)
end