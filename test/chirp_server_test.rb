require_relative 'test_helper'

require 'capybara'
require 'capybara/dsl'

require 'chirp_server'

require 'user_test_helper'

ENV['RACK_ENV'] = 'test'

class ChirpServerTest < MiniTest::Unit::TestCase
  include Capybara
  
  include UserTestHelper

  def setup
    Capybara.app = ChirpServer

    Ohm.flush
  end

  def test_user_can_signup
    signup 'anna'

    assert_equal '/channel', current_path
  end

  def test_user_can_login_and_logout
    create_user 'anna'

    login 'anna'

    assert_equal '/channel', current_path

    logout

    assert_equal '/', current_path
  end

  def test_user_can_chirp
    create_user 'anna'

    login 'anna'
    chirp text = 'Chirp from Anna!'

    assert_equal '/channel', current_path
    assert_match text, page.body
  end

  def test_user_chirp_must_be_broadcasted_to_followers
    anna, bea, carla = create_users *%w(anna bea carla)

    bea.follow anna
    carla.follow anna

    login 'anna'
    chirp text = 'Chirp from Anna!'
    logout

    login 'bea'

    assert_equal '/channel', current_path
    assert_match text, page.body

    logout

    login 'carla'

    assert_equal '/channel', current_path
    assert_match text, page.body

    logout
  end

  def test_user_chirp_must_be_broadcasted_to_mentions
    anna, bea, carla = create_users *%w(anna bea carla)

    login 'anna'
    chirp text = 'Chirp from Anna! @bea @carla'
    logout

    login 'bea'

    assert_equal '/channel', current_path
    assert_match text, page.body

    logout

    login 'carla'

    assert_equal '/channel', current_path
    assert_match text, page.body

    logout
  end

  def test_channel_page_must_display_correct_following_and_follower_count
    anna, bea, carla, donna, erika, farah = create_users *%w(anna bea carla donna erika farah)

    anna.follow bea
    anna.follow carla

    donna.follow anna
    erika.follow anna
    farah.follow anna

    login 'anna'
    
    assert_match /#{anna.following.size} Following/, page.body
    assert_match /#{anna.followers.size} Followers/, page.body
  end

  def test_channel_page_must_display_correct_chirp_and_mention_count
    anna, bea, carla = create_users *%w(anna bea carla)

    anna.follow bea
    
    chirp_multiple_times anna, 3, 'Chirp from Anna!'
    chirp_multiple_times bea, 3, 'Chirp from Bea!'
    chirp_multiple_times carla, 3, 'Chirp from Carla! @anna'

    login 'anna'

    assert_match /#{anna.chirps.size} Chirps/, page.body
    assert_match /#{anna.mentions.size} Mentions/, page.body
  end

  def test_channel_page_must_display_latest_chirps_and_mentions
    anna, bea, carla = create_users *%w(anna bea carla)

    anna.follow bea
    
    chirp_multiple_times anna, 3, 'Chirp from Anna!'
    chirp_multiple_times bea, 3, 'Chirp from Bea!'
    chirp_multiple_times carla, 3, 'Chirp from Carla! @anna'

    login 'anna'

    assert_includes page.body, 'Last Chirp from Anna!'
    assert_includes page.body, 'Another Chirp from Anna!'
    assert_includes page.body, 'First Chirp from Anna!'

    assert_includes page.body, 'Last Chirp from Bea!'
    assert_includes page.body, 'Another Chirp from Bea!'
    assert_includes page.body, 'First Chirp from Bea!'

    assert_includes page.body, 'Last Chirp from Carla! @anna'
    assert_includes page.body, 'Another Chirp from Carla! @anna'
    assert_includes page.body, 'First Chirp from Carla! @anna'
  end

  def test_user_page_must_display_correct_following_and_follower_count
    anna, bea, carla, donna, erika, farah = create_users *%w(anna bea carla donna erika farah)

    anna.follow bea
    anna.follow carla

    donna.follow anna
    erika.follow anna
    farah.follow anna
    
    visit '/anna'

    assert_match /#{anna.following.size} Following/, page.body
    assert_match /#{anna.followers.size} Followers/, page.body
  end

  def test_user_page_must_display_correct_chirp_and_mention_count
    anna, bea, carla = create_users *%w(anna bea carla)

    anna.follow bea
    
    chirp_multiple_times anna, 3, 'Chirp from Anna!'
    chirp_multiple_times bea, 3, 'Chirp from Bea!'
    chirp_multiple_times carla, 3, 'Chirp from Carla! @anna'

    visit '/anna'

    assert_match /#{anna.chirps.size} Chirps/, page.body
    assert_match /#{anna.mentions.size} Mentions/, page.body
  end

  def test_user_page_must_only_display_latest_chirps_from_user
    anna, bea, carla = create_users *%w(anna bea carla)

    anna.follow bea
    
    chirp_multiple_times anna, 3, 'Chirp from Anna!'
    chirp_multiple_times bea, 3, 'Chirp from Bea!'
    chirp_multiple_times carla, 3, 'Chirp from Carla! @anna'

    visit '/anna'

    assert_includes page.body, 'Last Chirp from Anna!'
    assert_includes page.body, 'Another Chirp from Anna!'
    assert_includes page.body, 'First Chirp from Anna!'

    refute_includes page.body, 'Last Chirp from Bea!'
    refute_includes page.body, 'Another Chirp from Bea!'
    refute_includes page.body, 'First Chirp from Bea!'

    refute_includes page.body, 'Last Chirp from Carla! @anna'
    refute_includes page.body, 'Another Chirp from Carla! @anna'
    refute_includes page.body, 'First Chirp from Carla! @anna'
  end

  def test_user_following_page_must_only_display_followed_users
    anna, bea, carla, donna = create_users *%w(anna bea carla donna erika farah gia hanna)

    anna.follow bea
    anna.follow carla

    carla.follow anna
    donna.follow anna
    
    visit '/anna/following'

    assert_includes page.body, bea.username
    assert_includes page.body, carla.username

    refute_includes page.body, donna.username
  end

  def test_user_followers_page_must_only_display_followers
    anna, bea, carla, donna = create_users *%w(anna bea carla donna erika farah gia hanna)

    anna.follow bea
    anna.follow carla

    carla.follow anna
    donna.follow anna
        
    visit '/anna/followers'

    assert_includes page.body, carla.username
    assert_includes page.body, donna.username

    refute_includes page.body, bea.username
  end

  def test_user_mentions_page_must_only_display_latest_mentions_for_user
    anna, bea, carla = create_users *%w(anna bea carla)

    anna.follow bea
    
    chirp_multiple_times anna, 3, 'Chirp from Anna!'
    chirp_multiple_times bea, 3, 'Chirp from Bea!'
    chirp_multiple_times carla, 3, 'Chirp from Carla! @anna'

    visit '/anna/mentions'

    assert_includes page.body, 'Last Chirp from Carla! @anna'
    assert_includes page.body, 'Another Chirp from Carla! @anna'
    assert_includes page.body, 'First Chirp from Carla! @anna'

    refute_includes page.body, 'Last Chirp from Anna!'
    refute_includes page.body, 'Another Chirp from Anna!'
    refute_includes page.body, 'First Chirp from Anna!'

    refute_includes page.body, 'Last Chirp from Bea!'
    refute_includes page.body, 'Another Chirp from Bea!'
    refute_includes page.body, 'First Chirp from Bea!'
  end

private

  def signup(username, password = nil)
    visit '/signup'

    fill_in 'username', :with => username
    fill_in 'password', :with => password
    fill_in 'password_confirmation', :with => password

    click_on 'Signup'
  end

  def login(username, password = nil)
    visit '/login'

    fill_in 'username', :with => username
    fill_in 'password', :with => password || username
    
    click_on 'Login'
  end

  def logout
    visit '/logout'
  end

  def chirp(text)
    fill_in 'chirp', :with => text

    click_on 'Chirp'
  end
end