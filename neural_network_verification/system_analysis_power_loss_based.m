% The points of evaluation for the system analysis based on what fraction
% of the active power is delivered at 1s. If the low-voltage ride through 
% control was entered the final power delivery should be at most 60% of the reference value 
power_output_fraction = [0.25, 0.5, 0.55, 0.6, 0.75, 0.9, 0.95, 0.98];
voltage_disturbance = linspace(0.2, 0.8, 19);

% 'Ground truth' boundary, extracted from simulations
true_voltage_disturbance = [0.36 0.37 0.38 0.39 0.4 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.5 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.6];
true_delta_T = [0.25 0.232 0.208 0.189 0.175 0.163 0.153 0.144 0.136 0.13 0.124 0.118 0.114 0.109 0.105 0.102 0.098 0.095 0.092 0.089 0.087 0.084 0.082 0.08 0.078];

% evaluate optimisation problem for previously defined points
max_delta_T_power_map = NaN(length(voltage_disturbance), length(power_output_fraction));
for ii = 1:length(power_output_fraction)
    for jj = 1:length(voltage_disturbance)
        max_delta_T_power_map(jj, ii) = Compute_Maximum_Delta_T_power_loss_based(voltage_disturbance(jj), power_output_fraction(ii));
        fprintf('Max Delta T: %5.3f s with Delta V = %4.3f p.u. and power output fraction = %5.1f %%\n', max_delta_T_power_map(jj, ii), voltage_disturbance(jj),  power_output_fraction(ii)*100);
    end
end

% plot the results
figure
grid on
hold on
plot(voltage_disturbance, max_delta_T_power_map)
plot(true_voltage_disturbance, true_delta_T, 'k--')
xlim([0.2, 0.8])
ylim([0.1, 0.25])
xlabel('Delta V [pu]')
ylabel('Delta t [s]')
leg = legend([compose("%5.1f",power_output_fraction*100), 'no power loss']);
title(leg,'Final power delivery \mu [%]')

% The largest allowable voltage disturbance for Delta T = 0.1s can be
% calculated with the following
max_delta_V_power_map = NaN(1, length(power_output_fraction));
for ii = 1:length(power_output_fraction)
    max_delta_V_power_map(1, ii) = Compute_Maximum_Delta_V_power_loss_based(0.1, power_output_fraction(ii));
    fprintf('Max Delta V: %4.3f p.u. with Delta T = 0.1 s and power output fraction = %5.1f %% \n', max_delta_V_power_map(1, ii), power_output_fraction(ii)*100);
end
