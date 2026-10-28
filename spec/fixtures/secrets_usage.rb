# frozen_string_literal: true

class ApiClient
  def api_key
    Rails.application.secrets.api_key
  end

  def secret_base
    Rails.application.secrets.secret_key_base
  end
end
