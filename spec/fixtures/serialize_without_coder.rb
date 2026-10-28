# frozen_string_literal: true

class Profile < ApplicationRecord
  serialize :preferences
  serialize :tags, Array
  serialize :metadata, coder: JSON
end
