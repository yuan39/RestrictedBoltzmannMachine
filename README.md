# --- WORK IN PROGRESS ---

## Description

Example scripts for a restricted Boltzmann machine (RBM), which is a type of generative model, have been written from scratch. No machine learning packages are used, providing an example of how to implement the underlying algorithms of an artificial neural network. The code is written in the Julia, a programming language with a syntax similar to Matlab.

The generative model is trained on both the features and labels of the MNIST dataset of handwritten digits. Samples drawn from the model are nearly indistinguishable from handwritten digits. The model is then used as a classifier by loading the features and running a Markov chain until the model has reached equilibrium, at which point the expected value of the label is tabulated. The model correctly classifies XX % of the handwritten digits in the test dataset.

## Download

* Download: [zip](https://github.com/jostmey/RestrictedBoltzmannMachine/zipball/master)
* Git: `git clone https://github.com/jostmey/RestrictedBoltzmannMachine`

## Requirements

The code requires the Julia runtime environment. Instructions on how to download and install Julia are [here](http://julialang.org/). The scripts have been developed using version 0.4 and do not work on previous versions of Julia.

The scripts require several modules, which have to be installed in the Julia environment. To add them, launch `julia` and run the following commands.

`Pkg.add("MNIST")`  
`Pkg.add("StatsBase")`  
`Pkg.add("Images")`

The first package contains the MNIST dataset of handwritten digits. The seconds package contains a tool for sampling from a set of weighted choices. The last package is used to render images.

## Run

Fitting the bias terms of the neurons representing the features using the dataset before training the neural network greatly improves the results. After fitting, the neural network can be trained, which can last anywhere from a few days to several weeks. To start the process, run the following commands.

`julia fit.jl > fit.out`  
`julia train.jl > train.out`

The scripts will automatically create a folder called `bin` where the neural network parameters will be saved. At this point, the neural network will be ready to use. To generate samples from the model, run the following command.

`julia generate.jl > generate.out`

A sequence of samples will be saved in the image file `generate.png`. To classify the handwritten digits in the test set, run the following command.

`julia classify.jl > classify.out`

The percentage of correct answers will be written at the end of the text file `test.out`.

## Performance

This package is not written for speed. It is meant to serve as a working example of an artificial neural network. As such, there is no GPU acceleration. Training using only the CPU can take days or even weeks. The training time can be shortened by reducing the number of updates, but this could lead to poorer performance on the test data. Consider using an exising machine learning package when searching for a deployable solution.

## Theory

###### Model

A restricted Boltzmann machines (RBM)s is a special type of Boltzmann machine, which is a generative model that can be trained to represent a dataset as a joint probability distribution. What this means is that if you draw a statistical sample from the model, it should look a new item was just added to the dataset. In otherwords, the model learns how to "make up" new examples based off of the dataset.

In a Boltzmann machine, the neurons are divided into two layers: A visible layer that represents the sensory input and a hidden layer that is determined solely by its connections to the visible layer. A Boltzmann machine can be though of as a probability distribution described by an energy function `E(v,h)`, where `v` and `h` are vectors used to represent the state of the neurons in the visible and hidden layers, respectively. The energy function takes the state of each neuron in the neural network and returns a scalar value. The probability of observing the neurons in a specific state is proportional to `exp(-E(v,h))` (assuming the temperature factor is one). The negative sign in front of the energy means that if the energy is high the probability will be low. Because the probability is proportional to `exp(-E(v,h))`, calculating an exact probability requires a normalization constast. The normalization constant is denoted `Z` and is called the partition function. `Z` is the sum of `exp(-E(v,h))` over all possible states of `v` and `h`, so in general calculating `Z` exactly is intractable.

The energy function `E(v,h) = -v'*W*h - b'*v - a'*h` is used in this model. The matrix `W` describes the weights of the connections between neurons in the visible and hidden layers, and the vectors `b` and `a` describe the biases of the neurons in the visible and hidden layers, respectively. The operator `'` transposes the vector -- in this way we always end up with a scalar value after each multiplication.

###### Sampling

Gibbs sampling is used to update the value of each neuron. Assuming that each neuron has only two states `0` and `1`, we can calculate the probability of the i<sup>th</sup> neuron being on given the state of the rest of the neural network. The probability can be found using the energy function `E(v,h)` by flipping the i<sup>th</sup> neuron so that it is on, which we will write as `E`<sub>`i=1`</sub>`(v,h)`. The probability that the <sup>i</sup> neuron is on is therefore proportional to `exp(-E`<sub>`i=1`</sub>`(v,h))`, and the total probability that the neuron is either on or off is proportional to `exp(-E`<sub>`i=0`</sub>`(v,h)) + exp(-E`<sub>`i=1`</sub>`(v,h))`. Because the total probability is always `1`, we can divide the probability by the total probability and get the same answer. What this means is that normalization constant `Z` will cancel out and the probability that the i<sup>th</sup> neuron is on will be `exp(-E`<sub>`i=1`</sub>`(v,h))` divided by `exp(-E`<sub>`i=0`</sub>`(v,h)) + exp(-E`<sub>`i=1`</sub>`(v,h))`. The term can be written as `Sigmoid(-E`<sub>`i=0`</sub>`(v,h) - E`<sub>`i=1`</sub>`(v,h))` by dividing the top and bottom by the numerator, where `Sigmoid` is the logistic function. The neural network is run by taking each neuron and calculating its probability of being having a value of `1`. The neuron is then randomly assigned a new state of either `0` or `1` based on this probability. Each neuron must be updated separately. After updating each neuron in the neural network a sufficient number of times, the model will reach what is called equilibrium.

In a RBM, connections between neurons in the same layer are removed. The only connections that exist are between the visible and hidden layers. Without cross connections, neurons in the same layer depend only on the state of the neurons in the other layer. Therefore, neurons in the same layer can be updated simultaneously in a single sweep. Given the state of the neurons in the visible layer, the state of the neurons in the hidden layer can be calculated in a single step, and vice versa.

###### Training

Boltzmann machines can be fit to a dataset by obtaining a maximum-likelihood estimation (MLE) of the neural network parameters. Typically, gradient ascent is used to optimize the log-likelihood of the model (taking the log of the likelihood does not effect the optimum points). The derivative is used to make small adjustments to parameters of the neural networks up the gradient. Changes are made to the weights in small, discrete steps determined by the value of the *learning rate*.

The derivative of the log-likelihood function for a neural nework is remarkably simple. It is the difference between two expectations. The first expectation is `<-dE(v,h)/du)>`<sub>`DATA`</sub>, where `u` is the parameter, is calculated over the dataset. The result is subtracted by the second expectation `<-dE(v,h)/du>`<sub>`MODEL`</sub>. Each of the two expectations can be estimated by collecting a set of samples, a process that is called Markov Chain Monte-Carlo. For the first expectation, the neurons in the visible layer is set to the values of an item in the dataset and the neurons in the hidden layer are updated until equilibrium is reached. For a RBM, only a single sweep is required to reach equilibrium. The latter expectation is harder to sample. It requires starting from a random configuration of the neurons in the visible and hidden layers, and sampling until the model reaches equilibrium. Because none of the neurons are clamped, it can take awhile to reach equilibrium... Persistent States...



###### Prior



###### Results




WORK IN PROGRESS... CHECK BACK LATER...

