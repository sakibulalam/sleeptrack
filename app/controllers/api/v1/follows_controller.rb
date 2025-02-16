class Api::V1::FollowsController < ApplicationController
  include Authenticatable

  def create
    begin
      user_to_follow = User.find(params[:user_id])
      existing_follow = current_user.active_follows.find_by(followed_id: user_to_follow.id)

      if existing_follow
        render json: { errors: [ "Already following this user" ] }, status: :unprocessable_entity
      else
        follow = current_user.active_follows.build(followed: user_to_follow)
        if follow.save
          render json: { message: "Successfully followed user" }, status: :created
        else
          render json: { errors: follow.errors.full_messages }, status: :unprocessable_entity
        end
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :not_found
    end
  end

  def destroy
    begin
      user_to_unfollow = User.find(params[:user_id])
      follow = current_user.active_follows.find_by(followed_id: user_to_unfollow.id)

      if follow
        follow.destroy
        render json: { message: "Successfully unfollowed user" }, status: :ok
      else
        render json: { error: "You are not following this user" }, status: :not_found
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :not_found
    end
  end

  def following
    following_users = current_user.following
    render json: following_users
  end

  def followers
    followers = current_user.followers
    render json: followers
  end
end
