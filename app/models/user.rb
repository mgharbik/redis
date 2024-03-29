class User < ActiveRecord::Base
	validates_presence_of :email

	# Code by The Redis Book
	def follow!(user)
		$redis.multi do
			$redis.sadd(self.redis_key(:following), user.id)
			$redis.sadd(user.redis_key(:followers), self.id)
		end
	end
  
	def unfollow!(user)
		$redis.multi do
			$redis.srem(self.redis_key(:following), user.id)
			$redis.srem(user.redis_key(:followers), self.id)
		end
	end
  
	def followers
		user_ids = $redis.smembers(self.redis_key(:followers))
		User.where(:id => user_ids)
	end

	def following
		user_ids = $redis.smembers(self.redis_key(:following))
		User.where(:id => user_ids)
	end

  	def friends
  		user_ids = $redis.sinter(self.redis_key(:following), self.redis_key(:followers))
  		User.where(:id => user_ids)
  	end

	def followed_by?(user)
		$redis.sismember(self.redis_key(:followers), user.id)
	end
  
	def following?(user)
		$redis.sismember(self.redis_key(:following), user.id)
	end

	def followers_count
		$redis.scard(self.redis_key(:followers))
	end

	def following_count
		$redis.scard(self.redis_key(:following))
	end
  
	def redis_key(str)
		"user:#{self.id}:#{str}"
	end


	def scored(score)
		if score > self.high_score
			$redis.zadd("highscores", score, self.id)
		end
	end

	def rank
		$redis.zrevrank("highscores", self.id) + 1
	end
  
	def high_score
		$redis.zscore("highscores", self.id).to_i
	end
  
	def self.top_3
		$redis.zrevrange("highscores", 0, 2).map{|id| User.find(id)}
	end

end