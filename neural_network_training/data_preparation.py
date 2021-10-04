import numpy as np
from scipy import io
import pickle


def convert_matlab_training_dataset():
    """
    Convert the simulation files from Matlab into a 'standard' form that are used throughout the process,
    here specifically the 40 trajectories for training. The function is very specific to the training_data.mat file.
    :return: nothing, but it stores the formatted dataset.
    """
    C = io.loadmat('../data_simulation/training_data.mat')

    time = np.concatenate(C['T12'][0], axis=0).round(decimals=5)
    external_voltage = np.concatenate(C['E12'][0], axis=0).round(decimals=3)
    disturbance_strength_Delta_V = np.concatenate(C['DV12'][0], axis=0).round(decimals=3)
    disturbance_length_Delta_t = np.concatenate(C['DT12'][0], axis=0).round(decimals=3)

    states_results = np.concatenate(C['X12'][0], axis=0)
    data_type = np.ones(states_results.shape)

    states_initial = np.repeat(states_results[::1001], repeats=1001, axis=0)
    states_prediction = np.zeros(states_results.shape)

    simulation_id = np.repeat(np.arange(40), repeats=1001).reshape((-1, 1))

    data_complete = {'time': time,
                     'external_voltage': external_voltage,
                     'disturbance_strength_Delta_V': disturbance_strength_Delta_V,
                     'disturbance_length_Delta_t': disturbance_length_Delta_t,
                     'states_initial': states_initial,
                     'states_results': states_results,
                     'states_prediction': states_prediction,
                     'data_type': data_type,
                     'simulation_id': simulation_id}

    with open('complete_data_training.pickle', 'wb') as f:
        pickle.dump(data_complete, f)


def convert_matlab_validation_dataset():
    """
    Convert the simulation files from Matlab into a 'standard' form that are used throughout the process,
    here specifically the 36 trajectories for testing. The function is very specific to the validation_data.mat file.
    :return: nothing, but it stores the formatted dataset.
    """
    C = io.loadmat('../data_simulation/validation_data.mat')

    time = np.concatenate(C['T12'][0], axis=0).round(decimals=5)
    external_voltage = np.concatenate(C['E12'][0], axis=0).round(decimals=3)
    disturbance_strength_Delta_V = np.concatenate(C['DV12'][0], axis=0).round(decimals=3)
    disturbance_length_Delta_t = np.concatenate(C['DT12'][0], axis=0).round(decimals=3)

    states_results = np.concatenate(C['X12'][0], axis=0)
    data_type = np.ones(states_results.shape)

    states_initial = np.repeat(states_results[::1001], repeats=1001, axis=0)
    states_prediction = np.zeros(states_results.shape)

    simulation_id = np.repeat(np.arange(36), repeats=1001).reshape((-1, 1))

    data_complete = {'time': time,
                     'external_voltage': external_voltage,
                     'disturbance_strength_Delta_V': disturbance_strength_Delta_V,
                     'disturbance_length_Delta_t': disturbance_length_Delta_t,
                     'states_initial': states_initial,
                     'states_results': states_results,
                     'states_prediction': states_prediction,
                     'data_type': data_type,
                     'simulation_id': simulation_id}

    with open('complete_data_validation.pickle', 'wb') as f:
        pickle.dump(data_complete, f)


def filter_data_set(complete_data_set, filter_indices):
    """
    filter a dataset given in the 'standard' form by specifying the relevant indices
    :param complete_data_set:
    :param filter_indices: indices that determine the elements to keep
    :return: a filter dataset, i.e. a subset of the input complete_data_set
    """
    complete_data_set_copy = complete_data_set.copy()
    complete_data_set_copy.update(time=complete_data_set_copy['time'][filter_indices],
                                  external_voltage=complete_data_set_copy['external_voltage'][filter_indices, :],
                                  disturbance_strength_Delta_V=complete_data_set_copy['disturbance_strength_Delta_V'][
                                                               filter_indices, :],
                                  disturbance_length_Delta_t=complete_data_set_copy['disturbance_length_Delta_t'][
                                                             filter_indices, :],
                                  states_initial=complete_data_set_copy['states_initial'][filter_indices, :],
                                  states_results=complete_data_set_copy['states_results'][filter_indices, :],
                                  states_prediction=complete_data_set_copy['states_prediction'][filter_indices, :],
                                  data_type=complete_data_set_copy['data_type'][filter_indices, :],
                                  simulation_id=complete_data_set_copy['simulation_id'][filter_indices, :],
                                  )

    return complete_data_set_copy


def prepare_training_and_validation_data(complete_data_training, complete_data_validation):
    """
    The complete_data_training and complete_data_validation include values every 0.001s, for the training process we
    use only every 10th value. Furthermore, the function returns the data in the format ready to be called in model.fit
    """
    subset_data_indices_single = np.zeros(4004, dtype=bool)

    subset_data_indices_single[0:101:10] = True
    subset_data_indices_single[101:1000:10] = True
    subset_data_indices_single[1001:1152:10] = True
    subset_data_indices_single[1152:2001:10] = True
    subset_data_indices_single[2002:2203:10] = True
    subset_data_indices_single[2203:3002:10] = True
    subset_data_indices_single[3003:3254:10] = True
    subset_data_indices_single[3254:4003:10] = True

    training_data_indices = np.tile(subset_data_indices_single.copy(), reps=10)
    validation_data_indices = np.tile(subset_data_indices_single.copy(), reps=9)

    training_data = filter_data_set(complete_data_training, training_data_indices)
    validation_data = filter_data_set(complete_data_validation, validation_data_indices)

    X_training = [training_data['time'],
                  training_data['external_voltage'],
                  training_data['disturbance_strength_Delta_V'],
                  training_data['disturbance_length_Delta_t']]

    y_training = np.split(training_data['states_results'],
                          indices_or_sections=17, axis=1) + np.split(np.zeros(training_data['states_results'].shape),
                                                                     indices_or_sections=17, axis=1)

    X_validation = [validation_data['time'],
                    validation_data['external_voltage'],
                    validation_data['disturbance_strength_Delta_V'],
                    validation_data['disturbance_length_Delta_t']]

    y_validation = np.split(validation_data['states_results'],
                            indices_or_sections=17, axis=1) + np.split(
        np.zeros(validation_data['states_results'].shape),
        indices_or_sections=17, axis=1)

    return X_training, y_training, X_validation, y_validation


def prepare_plotting_data(complete_data_training, complete_data_validation):
    """
    Use the complete training and validation data in plots that either are on the trajectory or not.
    """
    X_plot_on_trajectory = [complete_data_training['time'],
              complete_data_training['external_voltage'],
              complete_data_training['disturbance_strength_Delta_V'],
              complete_data_training['disturbance_length_Delta_t']]

    X_plot_off_trajectory = [complete_data_validation['time'],
                complete_data_validation['external_voltage'],
                complete_data_validation['disturbance_strength_Delta_V'],
                complete_data_validation['disturbance_length_Delta_t']]

    return X_plot_on_trajectory, X_plot_off_trajectory
