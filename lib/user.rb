require 'ohm'
require 'shield'

class User < Ohm::Model
  extend Shield::Model

  TRACK_MAX_LATEST_CHIRPS = 10
  TRACK_MAX_LATEST_CHANNEL = 10
  TRACK_MAX_LATEST_MENTIONS = 10

  attribute :username

  attribute :crypted_password

  set :following, User
  set :followers, User

  list :chirps, Chirp
  list :channel, Chirp
  list :mentions, Chirp

  index :username

  def self.fetch(username)
    self.find(:username => username).first
  end

  def password=(password)
    write_local :crypted_password, Shield::Password.encrypt(password)

    @password = password
  end

  def password_confirmation=(password_confirmation)
    @password_confirmation = password_confirmation
  end

  def follow(user)
    self.following << user
    user.followers << self
  end

  def unfollow(user)
    self.following.delete user
    user.followers.delete self
  end

  def chirp(text)
    chirp = Chirp.new
    chirp.author = self
    chirp.text = text
    chirp.save

    self.post_chirp chirp
    self.post_chirp_to_channel chirp
    self.broadcast_chirp_to_followers chirp
    self.broadcast_chirp_to_mentioned_users chirp

    chirp
  end

  def validate
    assert_present :username

    assert @password == @password_confirmation, 'Password and confirmation does not match.'
  end

protected

  def post_chirp(chirp)
    self.chirps.unshift chirp
    self.chirps.key.ltrim(0, User::TRACK_MAX_LATEST_CHIRPS - 1) if self.chirps.size > User::TRACK_MAX_LATEST_CHIRPS
  end

  def post_chirp_to_channel(chirp)
    self.channel.unshift chirp
    self.channel.key.ltrim(0, User::TRACK_MAX_LATEST_CHANNEL - 1) if self.channel.size > User::TRACK_MAX_LATEST_CHANNEL
  end

  def post_chirp_to_mentions(chirp)
    self.mentions.unshift chirp
    self.mentions.key.ltrim(0, User::TRACK_MAX_LATEST_MENTIONS - 1) if self.mentions.size > User::TRACK_MAX_LATEST_MENTIONS
  end

  def broadcast_chirp_to_followers(chirp)
    self.followers.all.each do |follower|
      follower.post_chirp_to_channel chirp
    end
  end

  def broadcast_chirp_to_mentioned_users(chirp)
    chirp.mentions.each do |mention|
      User.find(:username => mention[/^@(.*)/, 1]).each do |mentioned_user|
        mentioned_user.post_chirp_to_channel chirp unless mentioned_user == self || self.followers.include?(mentioned_user)
        mentioned_user.post_chirp_to_mentions chirp
      end
    end
  end
end