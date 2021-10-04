import numpy as np
import pickle
import tensorflow as tf
from pathlib import Path
import datetime
from neural_network_training.data_preparation import prepare_training_and_validation_data, prepare_plotting_data, \
    convert_matlab_training_dataset, convert_matlab_validation_dataset
from neural_network_training.PINN import PinnModel
from neural_network_training.plot_state_trajectories import plot_states_with_prediction


# load dataset (convert them from Matlab if not done before)
training_data_path = Path('complete_data_training.pickle')
validation_data_path = Path('complete_data_validation.pickle')

if not training_data_path.is_file():
    convert_matlab_training_dataset()

with open(training_data_path, "rb") as f:
    complete_data_training = pickle.load(f)

if not Path('complete_data_validation.pickle').is_file():
    convert_matlab_validation_dataset()

with open(validation_data_path, "rb") as f:
    complete_data_validation = pickle.load(f)

# data preparation for training and plotting
X_training, y_training, X_validation, y_validation = prepare_training_and_validation_data(complete_data_training,
                                                                                          complete_data_validation)

X_plot_on_trajectory, X_plot_off_trajectory = prepare_plotting_data(complete_data_training, complete_data_validation)

# set up logging of the training
file_name = datetime.datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]
# log_directory = Path('logs')

tensorboard_callback = tf.keras.callbacks.TensorBoard(log_dir=f'logs/{file_name}',
                                                      histogram_freq=5,
                                                      profile_batch=0,
                                                      write_graph=False)

# PINN model definition and setup
neurons_in_hidden_layer = [50, 50, 50]
model = PinnModel(neurons_in_hidden_layer=neurons_in_hidden_layer)


# training parameters (not subject to hyperparameter tuning yet.
learning_rate_scheduler = tf.keras.optimizers.schedules.ExponentialDecay(initial_learning_rate=0.01,
                                                                         decay_rate=0.99,
                                                                         decay_steps=100)

# loss weights to balance the different loss terms, heuristic for now, more details see paper
loss_weights = np.array([1, 0.01, 5, 5, 10, 1.5, 6.5, 28.8, 1.1, 2.2, 0.2, 2.3, 36.0, 1.5, 0.4, 15, 15,
                         0.008, 3.2, 0, 0, 0.05, 1.4, 4.0, 54, 3.5, 7.2, 1.2, 2.3, 8.6, 20.5, 11.3, 4.4, 1.1])

model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=learning_rate_scheduler),
              loss=[tf.keras.losses.MeanSquaredError()] * 34,
              loss_weights=loss_weights.tolist(),
              )

epochs = 2000
for _ in range(5):
    history = model.fit(X_training,
                        y_training,
                        initial_epoch=model.epoch_count,
                        validation_data=(X_validation, y_validation),
                        validation_freq=50,
                        epochs=model.epoch_count + epochs,
                        batch_size=int(X_training[0].shape[0]),
                        verbose=2,
                        shuffle=True,
                        callbacks=[tensorboard_callback])

    model.epoch_count = model.epoch_count + epochs

    results_on_trajectory = model.predict(X_plot_on_trajectory)
    complete_data_training['states_prediction'] = np.concatenate(results_on_trajectory, axis=1)[:, 0:17]
    complete_data_training['physics_prediction'] = np.concatenate(results_on_trajectory, axis=1)[:, 17:34]

    results_off_trajectory = model.predict(X_plot_off_trajectory)
    complete_data_validation['states_prediction'] = np.concatenate(results_off_trajectory, axis=1)[:, 0:17]
    complete_data_validation['physics_prediction'] = np.concatenate(results_off_trajectory, axis=1)[:, 17:34]

    simulation_ids_on_trajectory = [0, 31, 35, 39]
    for simulation_id in simulation_ids_on_trajectory:
        plot_states_with_prediction(complete_data_training, test_simulation_id=simulation_id)

    simulation_ids_off_trajectory = [17]
    for simulation_id in simulation_ids_off_trajectory:
        plot_states_with_prediction(complete_data_validation, test_simulation_id=simulation_id)

# save model weights, either to 
model.save_weights('model_weights.h5')

weights = model.get_weights()
for j in range(0, 4):
    np.savetxt('../neural_network_verification/W' + str(j) + '.csv', weights[2 * j], fmt='%s', delimiter=',')
    np.savetxt('../neural_network_verification/b' + str(j) + '.csv', weights[2 * j + 1], fmt='%s', delimiter=',')
