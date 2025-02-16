class Api::V1::AuthenticationController < ApplicationController
  def login
    user = User.find_by(name: params[:name])

    if user&.authenticate(params[:password])
      token = JWT.encode(
        { user_id: user.id, exp: 24.hours.from_now.to_i },
        Rails.application.credentials.secret_key_base
      )

      render json: { token: token }, status: :ok
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end
end
