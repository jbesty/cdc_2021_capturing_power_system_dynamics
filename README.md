# Capturing Power System Dynamics by Physics-Informed Neural Networks and Optimization

This repository is the official implementation of [Capturing Power System Dynamics by Physics-Informed Neural Networks and Optimization](https://arxiv.org/abs/2103.17004). 

## Environment

To install and activate the environment using conda run:

```setup
conda env create -f environment.yml
conda activate cdc_2021_converter_PINN
```

## Code structure

The repository is devided into three main sections:
- data_simulation
- neural_network_training
- neural_network_verification

The paper is focused on the training and verification, the data simulation is added for completeness, the files data_simulation/training_data.mat and data_simulation/validation_data.mat stem from the simulation.

## Neural network training
The file training_process.py acts as the central file that combines the data preparation, the model setup, model training, and model saving, as well as a basic visualisation. The file model_weihgts.h5 contains a set of trained weights that can be in the model and the folder 'logs' shows the corresponding training process. 

## Neural network verification
The csv files contain the trained weights and biases that are subsequently used in the verification. In a first step 'Tighten_ReLU_Bounds_MILP.m' computes tighter bounds of the ReLU units which are then stored in 'zk_hat_max.mat' and 'zk_hat_min.mat'. The files starting with 'Compute_Maximum_' contain the optimization problems that are solved in order to analyse the system. The files 'system_analysis_power_loss_based.m' and 'system_analysis_voltage_deviation_based.m' utilize these to produce Fig. 4. and Fig. 5 in the paper.  

## References
The implementation of the Physics-Informed Neural Networks is done in [TensorFlow](https://www.tensorflow.org) (Martín Abadi et al., TensorFlow: Large-scale machine learning on heterogeneous systems, 2015. Software available from tensorflow.org.). 
The neural network verification is an adaption from [Verification of neural networkbehaviour: Formal guarantees for power system applications](https://ieeexplore.ieee.org/abstract/document/9141308) (A. Venzke and S. Chatzivasileiadis, “Verification of neural networkbehaviour: Formal guarantees for power system applications,”IEEETransactions on Smart Grid, vol. 12, no. 1, pp. 383–397, 2021.)
We furthermore use [Gurobi](https://www.gurobi.com) and [YALMIP](https://yalmip.github.io/) (J. Löfberg, “Yalmip : A toolbox for modeling and optimization in matlab,” in In Proceedings of the CACSD Conference, Taipei, Taiwan, 2004.) for solving the resulting optimization problems.