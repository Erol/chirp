require_relative 'test_helper'

require 'user'
require 'chirp'

require 'user_test_helper'

class UserTest < MiniTest::Unit::TestCase
  include UserTestHelper

  def setup
    Ohm.flush
  end

  def test_user_must_have_empty_defaults
    anna = create_user 'anna'

    assert_empty anna.following
    assert_empty anna.followers

    assert_empty anna.chirps
    assert_empty anna.channel
    assert_empty anna.mentions
  end

  def test_user_can_follow_and_unfollow_another_user
    anna, bea = create_users *%w(anna bea)

    anna.follow bea

    assert_includes anna.following, bea
    assert_includes bea.followers, anna

    anna.unfollow bea

    refute_includes anna.following, bea
    refute_includes bea.followers, anna
  end

  def test_user_chirp_must_post_to_own_channel
    anna = create_user 'anna'

    chirp = anna.chirp 'Chirp!'

    assert_includes anna.channel.all, chirp
  end

  def test_user_chirp_must_broadcast_to_followers
    anna, bea, carla = create_users *%w(anna bea carla)

    bea.follow anna
    carla.follow anna

    chirp = anna.chirp 'Chirp!'

    assert_includes bea.channel, chirp
    assert_includes carla.channel, chirp
  end

  def test_user_chirp_must_broadcast_to_mentioned_users
    anna, bea, carla = create_users *%w(anna bea carla)

    chirp = anna.chirp '@bea @carla Chirp!'

    assert_includes bea.channel, chirp
    assert_includes carla.channel, chirp
  end

  def test_self_mention_must_only_broadcast_to_self_once
    anna = create_user 'anna'

    chirp = anna.chirp '@anna Chirp!'

    assert_equal 1, anna.channel.size
  end

  def test_follower_mention_must_only_broadcast_to_follower_once
    anna, bea = create_users *%w(anna bea)

    bea.follow anna

    chirp = anna.chirp '@bea Chirp!'

    assert_equal 1, bea.channel.size
  end

  def test_user_chirp_must_not_broadcast_to_non_followers_and_non_mentioned_users
    anna, bea, carla, donna, erica = create_users *%w(anna bea carla donna erica)

    bea.follow anna

    chirp = anna.chirp '@carla Chirp!'

    refute_includes donna.channel.all, chirp
    refute_includes erica.channel.all, chirp
  end

  def test_user_can_track_own_chirps
    anna, bea, carla = create_users *%w(anna bea carla)

    anna.follow bea
    bea.follow anna

    anna_chirp = anna.chirp 'Chirp!'
    bea_chirp = bea.chirp 'Chirp!'

    assert_includes anna.chirps.all, anna_chirp
    assert_includes bea.chirps.all, bea_chirp

    refute_includes anna.chirps.all, bea_chirp
    refute_includes bea.chirps.all, anna_chirp

    refute_includes carla.chirps.all, anna_chirp
    refute_includes carla.chirps.all, bea_chirp    
  end

  def test_user_can_track_mentions
    anna, bea, carla = create_users *%w(anna bea carla)

    anna_chirp = anna.chirp '@bea Chirp!'
    bea_chirp = bea.chirp '@anna Chirp!'

    assert_includes anna.mentions.all, bea_chirp
    assert_includes bea.mentions.all, anna_chirp

    refute_includes anna.mentions.all, anna_chirp
    refute_includes bea.mentions.all, bea_chirp

    refute_includes carla.mentions.all, anna_chirp
    refute_includes carla.mentions.all, bea_chirp    
  end

  def test_user_can_track_a_maximum_number_of_latest_own_chirps
    anna = create_user 'anna'

    anna.chirp 'Chirp!'

    chirps = chirp_multiple_times anna, User::TRACK_MAX_LATEST_CHIRPS, 'Chirp!'

    assert_equal User::TRACK_MAX_LATEST_CHIRPS, anna.channel.size
    assert_equal chirps.last, anna.channel[0]
    assert_equal chirps.first, anna.channel[User::TRACK_MAX_LATEST_CHIRPS - 1]
  end

  def test_user_can_track_a_maximum_number_of_latest_chirps_in_channel
    anna, bea, carla = create_users *%w(anna bea carla)

    anna.follow bea

    anna.chirp 'Chirp!'

    chirps = chirp_multiple_times anna, User::TRACK_MAX_LATEST_CHIRPS, 'Chirp!'

    assert_equal User::TRACK_MAX_LATEST_CHANNEL, anna.channel.size
    assert_equal chirps.last, anna.channel[0]
    assert_equal chirps.first, anna.channel[User::TRACK_MAX_LATEST_CHANNEL - 1]

    chirps = chirp_multiple_times bea, User::TRACK_MAX_LATEST_CHIRPS, 'Chirp!'

    assert_equal User::TRACK_MAX_LATEST_CHANNEL, anna.channel.size
    assert_equal chirps.last, anna.channel[0]
    assert_equal chirps.first, anna.channel[User::TRACK_MAX_LATEST_CHANNEL - 1]

    chirps = chirp_multiple_times carla, User::TRACK_MAX_LATEST_CHIRPS, 'Chirp! @anna'

    assert_equal User::TRACK_MAX_LATEST_CHANNEL, anna.channel.size
    assert_equal chirps.last, anna.channel[0]
    assert_equal chirps.first, anna.channel[User::TRACK_MAX_LATEST_CHANNEL - 1]
  end

  def test_user_can_track_a_maximum_number_of_latest_mentions
    anna, bea = create_users *%w(anna bea)

    bea.chirp '@anna Chirp!'

    chirps = chirp_multiple_times bea, User::TRACK_MAX_LATEST_CHIRPS, 'Chirp! @anna'

    assert_equal User::TRACK_MAX_LATEST_MENTIONS, anna.mentions.size
    assert_equal chirps.last, anna.mentions[0]
    assert_equal chirps.first, anna.mentions[User::TRACK_MAX_LATEST_MENTIONS - 1]
  end
end