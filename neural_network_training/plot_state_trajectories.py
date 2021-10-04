import numpy as np
import matplotlib.pyplot as plt
from neural_network_training.data_preparation import filter_data_set


def plot_states_with_prediction(test_data, test_simulation_id):
    """
    Simple plot function to visualise the prediction and the ground truth for a specified trajectory.

    :param test_data: the full test data set with dict elements for 'time', 'states_results', 'states_prediction',
    'simulation_id', 'disturbance_strength_Delta_V', and 'disturbance_length_Delta_t'
    :param test_simulation_id: integer to identify a single trajectory that will be plotted
    :return: nothing, a plot will be shown
    """

    plot_data_indices = np.isin(test_data['simulation_id'], test_simulation_id).reshape(-1)
    plot_data = filter_data_set(test_data, plot_data_indices)

    # defining how to split and name the states
    voltage_states = [4, 5, 6, 9, 11, 12]
    voltage_state_names = ['Vmf', 'Vd', 'Vq', 'Vpcc', 'Ed', 'Eq']
    current_states = [2, 3, 13, 14]
    current_state_names = ['id', 'iq', 'ix', 'iy']
    power_states = [8, 10, 15, 16]
    power_state_names = ['Pvsc', 'Qvsc', 'Ptotal', 'Qtotal']
    other_states = [0, 1, 7]
    other_state_names = ['Thetapll', 'Mw', 'omegapll']

    fig, axs = plt.subplots(ncols=1, nrows=4, sharex='all', sharey='row', figsize=(5, 16))

    for ii, state in enumerate(voltage_states):
        axs[0].plot(plot_data['time'],
                    plot_data['states_results'][:, state:state + 1],
                    color=f'C{ii}',
                    linestyle='dashed')
        axs[0].plot(plot_data['time'],
                    plot_data['states_prediction'][:, state:state + 1],
                    color=f'C{ii}',
                    linestyle='solid',
                    label=voltage_state_names[ii])

    for ii, state in enumerate(current_states):
        axs[1].plot(plot_data['time'],
                    plot_data['states_results'][:, state:state + 1],
                    color=f'C{ii}',
                    linestyle='dashed')
        axs[1].plot(plot_data['time'],
                    plot_data['states_prediction'][:, state:state + 1],
                    color=f'C{ii}',
                    linestyle='solid',
                    label=current_state_names[ii])

    for ii, state in enumerate(power_states):
        axs[2].plot(plot_data['time'],
                    plot_data['states_results'][:, state:state + 1],
                    color=f'C{ii}',
                    linestyle='dashed')
        axs[2].plot(plot_data['time'],
                    plot_data['states_prediction'][:, state:state + 1],
                    color=f'C{ii}',
                    linestyle='solid',
                    label=power_state_names[ii])

    for ii, state in enumerate(other_states):
        axs[3].plot(plot_data['time'],
                    plot_data['states_results'][:, state:state + 1],
                    color=f'C{ii}',
                    linestyle='dashed')
        axs[3].plot(plot_data['time'],
                    plot_data['states_prediction'][:, state:state + 1],
                    color=f'C{ii}',
                    linestyle='solid',
                    label=other_state_names[ii])

    axs[0].set_title(label=f'SimID {test_simulation_id}: Delta V ='
                           f' {plot_data["disturbance_strength_Delta_V"][0, 0]} and '
                           f'Delta t = {plot_data["disturbance_length_Delta_t"][0, 0]}')
    axs[0].legend(loc='center right')
    axs[1].legend(loc='upper right')
    axs[2].legend(loc='upper right')
    axs[3].legend(loc='center right')
    axs[3].set_xlabel('time')
    axs[0].set_ylabel('Voltage')
    axs[1].set_ylabel('Current')
    axs[2].set_ylabel('Power')
    plt.show()
