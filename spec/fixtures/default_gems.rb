# frozen_string_literal: true

require 'csv'
require 'base64'
require 'json'
require 'bigdecimal'

class DataExporter
  def export(data)
    CSV.generate { |csv| data.each { |row| csv << row } }
  end
end
