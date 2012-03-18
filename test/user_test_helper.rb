module UserTestHelper
private
  def create_users(*args)
    args.inject [] do |users, username|
      users << create_user(username)
      users
    end
  end

  def create_user(username)
    User.create :username => username, :password => username, :password_confirmation => username
  end

  def chirp_multiple_times(user, repetitions, text)
    chirps = []

    chirps << user.chirp("First #{text}")
    (repetitions - 2).times do
      chirps << user.chirp("Another #{text}")
    end
    chirps << user.chirp("Last #{text}")

    chirps
  end
end