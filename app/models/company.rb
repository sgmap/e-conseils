# frozen_string_literal: true

class Company < ApplicationRecord
  NUMBER_PATTERN = '[0-9]{9,14}'

  validates :name, presence: true

  def to_s
    name
  end

  def name_short
    name.first(40)
  end
end
