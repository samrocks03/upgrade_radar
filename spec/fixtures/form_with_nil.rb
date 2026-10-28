# frozen_string_literal: true

class FormsHelper
  def search_form
    form_with model: nil, url: "/search", method: :get do |f|
      f.text_field :query
    end
  end
end
