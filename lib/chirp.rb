require 'ohm'

class Chirp < Ohm::Model
  attribute :text

  reference :author, User

  def words
    return @words if defined?(@words)

    @words = text.split(/[^a-zA-Z0-9@_]/).reject(&:empty?)
  end

  def mentions
    return @mentions if defined?(@mentions)

    self.words.inject [] do |mentions, word|
      mentions << word if word =~ /^@/
      mentions
    end.uniq
  end
end