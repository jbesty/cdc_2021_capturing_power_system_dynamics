import math
import tensorflow as tf


class PinnModel(tf.keras.models.Model):
    """
    Wrapper around the DenseCoreNetwork that implements the calculation of the physics loss. This includes the
    calculation of the temporal derivative for the differential states ('calculate_time_derivatives') and the
    evaluation of the physical equations given the state approximations ('equation_physics').
    """

    def __init__(self, neurons_in_hidden_layer, n_states=17, seed=12345, *args,
                 **kwargs):
        super().__init__(*args, **kwargs)

        # set seed to allow for reproducability
        tf.random.set_seed(seed)

        # setting up the inner neural network
        self.DenseCoreNetwork = DenseCoreNetwork(n_states=17,
                                                 neurons_in_hidden_layer=neurons_in_hidden_layer)

        # epoch counter
        self.epoch_count = 0

        # general system parameters
        self.n_states = n_states
        self.n_differential_states = 5

        # component specific parameters
        self.Ta = 0.1
        self.Tq = 0.05
        self.Tp = 0.1
        self.Kpw = 0.1
        self.Kiw = 0

        self.R = 0.0125
        self.L = 0.0375

        # reference values
        self.Pext = 0.8
        self.Qext = 0.2
        self.wref = math.pi * 50 * 2

    def call(self, inputs, training=None, mask=None):
        network_output, network_output_t = self.calculate_time_derivatives(inputs=inputs)

        network_output_physics = self.equation_physics(inputs, network_output, network_output_t)

        # return each state and the residual of each equation separately so that there can be a loss weighing and
        # specific loss function for each term. This allows to stick with the build-in Tensorflow functions
        # model.compile and model.fit.
        return tf.split(network_output, num_or_size_splits=self.n_states, axis=1) + \
               tf.split(network_output_physics, num_or_size_splits=self.n_states, axis=1)

    def equation_physics(self, inputs, network_output, network_output_t):
        _, E, _, _ = inputs

        # split the network output into the single states and their temporal derivatives (indicated by the suffix '_t'
        # !!! the order of these states needs to be consistent throughout the entire code
        [theta_pll, Mw, i_d, i_q, V_mf, v_d, v_q, omega_pll, P_vsc, V_pcc, Q_vsc, E_d, E_q, i_x, i_y, P_total,
         Q_total] = tf.split(network_output, num_or_size_splits=self.n_states, axis=1)

        [theta_pll_t, Mw_t, id_t, iq_t, Vmf_t] \
            = tf.split(network_output_t, num_or_size_splits=self.n_differential_states, axis=1)

        # calculate the residuals of the system of differential algebraic equations.
        res1 = -theta_pll_t + self.Kpw * v_q * self.wref
        res2 = - Mw_t + self.Kiw * v_q

        res3 = -id_t + (self.Pext / V_mf - i_d) / self.Tp
        res4 = -iq_t + (- self.Qext / V_mf - i_q) / self.Tq

        res5 = -Vmf_t + (tf.sqrt(v_d ** 2 + v_q ** 2) - V_mf) / self.Ta

        res6 = - i_d * self.R + omega_pll * self.L * i_q + v_d - E * tf.cos(theta_pll)
        res7 = - i_q * self.R - omega_pll * self.L * i_d + v_q + E * tf.sin(theta_pll)

        res8 = -omega_pll + self.Kpw * v_q + 1

        res9 = -P_vsc + v_d * i_d + v_q * i_q
        res10 = -V_pcc + tf.sqrt(v_d ** 2 + v_q ** 2)
        res11 = -Q_vsc - v_d * i_q + v_q * i_d

        res12 = -E_d + E * tf.cos(theta_pll)
        res13 = -E_q - E * tf.sin(theta_pll)

        res14 = -i_x + i_d * tf.cos(theta_pll) - i_q * tf.sin(theta_pll)
        res15 = -i_y + i_d * tf.sin(theta_pll) + i_q * tf.cos(theta_pll)

        res16 = -P_total + E_d * i_d + E_q * i_q
        res17 = -Q_total + E_q * i_d - E_d * i_q

        network_output_physics = tf.concat([res1, res2, res3, res4, res5, res6, res7, res8, res9, res10,
                                            res11, res12, res13, res14, res15, res16, res17], axis=1)

        return network_output_physics

    def calculate_time_derivatives(self, inputs):
        time_input, _, Delta_V, Delta_t = inputs

        list_network_output_t = []

        # calculate the gradients with respect to time_input for the differential states
        for state in range(self.n_differential_states):
            with tf.GradientTape(watch_accessed_variables=False,
                                 persistent=False) as grad_t:
                grad_t.watch(time_input)
                network_output_single = self.DenseCoreNetwork(inputs=[time_input,
                                                                      Delta_V,
                                                                      Delta_t])[:, state:state + 1]

                network_output_t_single = grad_t.gradient(network_output_single,
                                                          time_input,
                                                          unconnected_gradients='zero')
            list_network_output_t.append(network_output_t_single)

        # call the DenseCoreNetwork for the entire state approximation and combine the derivatives for the
        # differential states
        network_output = self.DenseCoreNetwork(inputs=[time_input, Delta_V, Delta_t])
        network_output_t = tf.concat(list_network_output_t, axis=1)

        return network_output, network_output_t


class DenseCoreNetwork(tf.keras.models.Model):
    """
    The central element of PINNs, a 'classical' neural network. It takes as inputs the variables t,
    and the additional characteristics to distinguish the trajectories. It outputs the values which represent the
    state variables. The input tensors need to be two dimensional (axis 0: batch dimension)

    Keyword arguments
    n_states -- the number of states (int)
    neurons_in_hidden_layer -- neurons per hidden layer (list of ints)
    """

    def __init__(self, n_states: int, neurons_in_hidden_layer: list):
        super(DenseCoreNetwork, self).__init__()

        self.hidden_layer_0 = tf.keras.layers.Dense(units=neurons_in_hidden_layer[0],
                                                    activation=tf.keras.activations.relu,
                                                    use_bias=True,
                                                    kernel_initializer=tf.keras.initializers.glorot_normal,
                                                    bias_initializer=tf.keras.initializers.zeros,
                                                    name='first_layer')

        self.hidden_layer_1 = tf.keras.layers.Dense(units=neurons_in_hidden_layer[1],
                                                    activation=tf.keras.activations.relu,
                                                    use_bias=True,
                                                    kernel_initializer=tf.keras.initializers.glorot_normal,
                                                    bias_initializer=tf.keras.initializers.zeros,
                                                    name='hidden_layer_1')

        self.hidden_layer_2 = tf.keras.layers.Dense(units=neurons_in_hidden_layer[2],
                                                    activation=tf.keras.activations.relu,
                                                    use_bias=True,
                                                    kernel_initializer=tf.keras.initializers.glorot_normal,
                                                    bias_initializer=tf.keras.initializers.zeros,
                                                    name='hidden_layer_2')

        self.dense_output_layer = tf.keras.layers.Dense(units=n_states,
                                                        activation=tf.keras.activations.linear,
                                                        use_bias=True,
                                                        kernel_initializer=tf.keras.initializers.glorot_normal,
                                                        bias_initializer=tf.keras.initializers.zeros,
                                                        name='output_layer')

    def call(self, inputs, training=None, mask=None):
        concatenated_input = tf.concat(inputs, axis=1, name='input_concatenation')
        hidden_layer_0_output = self.hidden_layer_0(concatenated_input)
        hidden_layer_1_output = self.hidden_layer_1(hidden_layer_0_output)
        hidden_layer_2_output = self.hidden_layer_2(hidden_layer_1_output)
        network_output = self.dense_output_layer(hidden_layer_2_output)
        return network_output
