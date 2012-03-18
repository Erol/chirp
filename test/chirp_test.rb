require_relative 'test_helper'

require 'chirp'

class UserTest < MiniTest::Unit::TestCase
  def setup
    Ohm.flush
  end

  def test_chirp_can_parse_words
    chirp = Chirp.new :text => 'anna, bea and carla. donna'

    assert_includes chirp.words, 'anna'
    assert_includes chirp.words, 'bea'
    assert_includes chirp.words, 'carla'
    assert_includes chirp.words, 'and'
    assert_includes chirp.words, 'donna'

    refute_includes chirp.words, ','
    refute_includes chirp.words, '.'
  end

  def test_chirp_can_parse_mentions
    chirp = Chirp.new :text => '@anna @bea carla donna @erica'

    assert_includes chirp.mentions, '@anna'
    assert_includes chirp.mentions, '@bea'
    assert_includes chirp.mentions, '@erica'

    refute_includes chirp.mentions, 'carla'
    refute_includes chirp.mentions, 'donna'
  end
end