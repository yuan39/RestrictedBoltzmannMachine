##########################################################################################
# Author: Jared L. Ostmeyer
# Date Started: 2015-12-23
# Environment: Julia v0.4
# Purpose: Test restricted Boltzmann machine as a classifier.
##########################################################################################

##########################################################################################
# Packages
##########################################################################################

	# Load tools for sampling N-way outcomes according to a set of weights.
	#
	using StatsBase

##########################################################################################
# Dataset
##########################################################################################

	# Load package of the MNIST dataset.
	#
	using MNIST

	# Load the dataset.
	#
	data = testdata()

	# Scale feature values to be between 0 and 1.
	#
	features = data[1]'
	features /= 255.0

	# Copy over the labels.
	#
	labels = data[2]

	# Size of the dataset.
	#
	N_datapoints = size(features, 1)

##########################################################################################
# Settings
##########################################################################################

	# Schedule for updating the neural network.
	#
	N_equilibrate = 10
	N_samples = 100

	# Number of neurons in each layer.
	#
	N_x = 28^2
	N_z = 10
	N_h = 500

	# Load neural network parameters.
	#
	b_x = readcsv("bin/train_b_x.csv")
	W_xh = readcsv("bin/train_W_xh.csv")
	b_z = readcsv("bin/train_b_z.csv")
	W_zh = readcsv("bin/train_W_zh.csv")
	b_h = readcsv("bin/train_b_h.csv")

##########################################################################################
# Methods
##########################################################################################

	# Activation functions.
	#
	sigmoid(x) = 1.0./(1.0+exp(-x))
	softmax(x) = exp(x)./sum(exp(x))

	# Sampling methods.
	#
	state(p) = 1.0*(rand(size(p)) .<= p)
	choose(p) = ( y = zeros(size(p)) ; for i = 1:size(p, 2) j = sample(WeightVec(p[:,i])) ; y[j,i] = 1.0 end  ; y )

##########################################################################################
# Test
##########################################################################################

	# Print header.
	#
	println("RESPONSES")

	# Track percentage of guesses that are correct.
	#
	N_correct = 0.0
	N_tries = 0.0

	# Classify each item in the dataset.
	#
	for i = 1:N_datapoints

		# Track expectation of z.
		#
		Ez = zeros(N_z)

		# Repeatedly sample the model.
		#
		for j = 1:N_samples

			# Load the features into the visible layer.
			#
			px = features[i,:]'
			x = state(px)

			# Load random label into the visible layer.
			#
			pz = rand(N_z)
			z = choose(pz)

			# Repeated passes of Gibbs sampling.
			#
			for k = 1:N_equilibrate

				ph = sigmoid(W_xh'*x+W_zh'*z+b_h)
				h = state(ph)

				pz = softmax(W_zh*h+b_z)
				z = choose(pz)

			end

			# Update expectation of the label.
			#
			Ez += pz/N_samples

		end

		# Update percentage of guesses that are correct.
		#
		guess = findmax(Ez)[2]-1
		answer = round(Int, labels[i])
		if guess == answer
			N_correct += 1.0
		end
		N_tries += 1.0

		# Print response.
		#
		println("  i = $(i), Guess = $(guess), Answer = $(answer)")

	end

##########################################################################################
# Results
##########################################################################################

	# Print progress report.
	#
	println("SCORE")
	println("  Correct = $(round(100.0*N_correct/N_tries, 5))%")
	println("")

