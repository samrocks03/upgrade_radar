# frozen_string_literal: true

class Lead < ApplicationRecord
  enum status: { draft: 0, published: 1, archived: 2 }
  enum category: { blog: 0, news: 1 }
end
