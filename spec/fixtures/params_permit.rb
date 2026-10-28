# frozen_string_literal: true

class UsersController < ApplicationController
  def create
    user_params = params.require(:user).permit(:name, :email, :role)
    User.create!(user_params)
  end

  def update
    attrs = params.require(:user).permit(:name, :email)
    @user.update!(attrs)
  end
end
