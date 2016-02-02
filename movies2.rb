class User
	
	# create a new user
	# get the id, start a new map of movies to ratings, keep track of prediction
	# and number of ratings
	def initialize (id)
		@user_id = id
		@movie_ratings = Hash.new()
		@prediction = 0
		@total_ratings = 0
	end
	
	# fix/update the prediction by re-averaging
	# update total ratings by incrementing
	def fix_prediction(rating)
		@prediction = ( (@prediction * @total_ratings) + rating ) / (@total_ratings + 1.0)
		@total_ratings += 1
	end
	
	# add a movie and a rating to the user's rating map
	# adjust prediction for future movies
	def add(movie, rating)
		@movie_ratings[movie] = rating
		fix_prediction(rating)
	end
	
	def get_movie_ratings
		@movie_ratings
	end
	
	def get_prediction
		@prediction
	end
end

class Movie
	
	# create a new movie
	# start with an average rating of 0
	# initialize array of users that have rated movie
	def initialize(name)
		@movie_name = name
		@average_rating = 0.0
		@num_ratings = 0
		@users = Array.new
	end
	
	# re-adjust the average rating of the movie
	def fix_rating(new_rating)
		@average_rating = ( (@average_rating * @num_ratings) + new_rating ) / (@num_ratings + 1.0)
		@num_ratings = @num_ratings + 1
	end
	
	# add to array of users who have reviewed the movie
	def add_user (user_id)
		@users.push(user_id)
	end
	
	def get_users
		@users
	end
end

class MovieData
	
	def initialize(foldername)
		@filename = 'u.data'
		# map of user ids created to users
		@users_created = Hash.new
		# map of movies created to movies
		@movies_created = Hash.new
		
		# load the data into the objects
		load_data
	end
	
	# def MovieData.initialize(foldername, flag)		
	# end
	
	def load_data
		# open the file
		# puts "Enter file name: "
		fn = $stdin.gets.chomp
		file = open(fn)
		
		# split each line and move to separate_data method
		while (line = file.gets)
			numbers = line.split(' ')
			separate_data(numbers)
		end
		
		# close file
		file.close
	end
	
	# take each line, separate to numbers, and store lines
	def separate_data(num)
		user_id = num.shift.to_i
		movie_id = num.shift.to_i
		rating = num.shift.to_f
		
		# fix the rating if the movie has been previously rated
		# otherwise create the movie object and add the first rating
		# also add the movie to the movie_created map
		if @movies_created.has_key? (movie_id)
			@movies_created[movie_id].fix_rating(rating)
			@movies_created[movie_id].add_user(user_id)
		else
			movie = Movie.new(movie_id)
			movie.fix_rating(rating)
			movie.add_user(user_id)
			@movies_created[movie_id] = movie
		end
		
		# if user has already been created, then just add to their list of reviewed movies
		# otherwise, create and initialize a user
		if @users_created.has_key? (user_id)
			@users_created[user_id].add(movie_id, rating)
		else
			user = User.new(user_id)
			user.add(movie_id, rating)
			@users_created[user_id] = user
		end
	end
	
	def rating(user_id, movie_id)
		# get the necessary movie map from the user
		u = @users_created[user_id]
		user_rating = u.get_movie_ratings
		
		# check to see if the user has the movie
		# if he does, return the rating
		# if he doesn't, return 0
		if user_rating.has_key? (movie_id)
			return user_rating[movie_id]
		else 
			return 0
		end
	end
	
	def predict(user_id)
		# generate the user and get the prediction
		u = @users_created[user_id]
		u.get_prediction
	end
	
	def movies(user_id)
		# generate the user
		# retrieve the map of movies to ratings
		# get keys
		u = @users_created[user_id]
		user_rating = u.get_movie_ratings
		user_rating.keys
	end
	
	def viewers(movie_id)
		# generate the correct movie object
		# get the user array
		m = @movies_created[movie_id]
		m.get_users
	end
	
	def generate_results
		results = Array.new
	
		# iterate through users
		@users_created.each  { |key, value|
			# get movie list
			u = @users_created[key]
			movie_list = u.get_movie_ratings
			# puts movie_list
			movie_list.each { |key, value|
				# set up array such that [user, movie, rating, prediction]
				user_array = Array.new
				user_array.push(u)
				user_array.push(key)
				user_array.push(value)
				user_array.push(u.get_prediction)
				
				# push this array into results
				results.push(user_array)
			}
		}
		
		return results
	end
	
	def run_test(k)
	end
	
	def run_test
		results = generate_results
		
		movietest = MovieTest.new(results)
		puts movietest.to_a
	end
end

class MovieTest
	
	def initialize (results)
		# initialize with 2D array
		# each inner array is composed [user, movie, rating, prediction]
		@results = results
		@error = Hash.new
		
		@results.each do |user_array|
			rating = user_array[2]
			prediction = user_array[3]
			@error[user_array] = rating - prediction
		end
	end
	
	# average prediction error
	def mean_error
		array_errors = @error.values
		mean(array_errors)
	end
	
	# gest the average of an array
	def mean (new_array)
		new_array.inject { |sum, e1| sum + e1 } / new_array.size
	end
	
	# standard deviation of prediction error
	def stddev
		m = mean_error
		array_errors = @error.values
		variance = array_errors.inject(0) { |accum, i| accum + (i - m) ** 2 } / array_errors.size
		Math.sqrt(variance)
	end
	
	# root mean square of error
	def rms
		squares = @error.values.map { |e| e*2 }
		return Math.sqrt(mean(squares))
	end
	
	# returns results in array form
	def to_a
		@results.each do |user_array|
			puts "[ " + user_array[0].to_s + ", " + user_array[1].to_s + ", " + user_array[2].to_s + ", " + user_array[3].to_s + " ] "
		end
	end
		
end