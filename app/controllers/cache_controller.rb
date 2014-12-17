class CacheController < ApplicationController
  include ClassLogger

  before_filter :check_permission
  rescue_from Errors::ClientError, with: :handle_client_error

  def clear
    logger.warn "Clearing all cache entries at request of #{current_user.real_user_id}"
    Rails.cache.clear
    render :json => {cache_cleared: true}
  end

  def delete
    key = params['key']
    deleted = Rails.cache.delete(key)
    logger.warn "Deleted cache_key #{key} at request of #{current_user.real_user_id}"
    render json: {deleted: deleted}
  end

  def warm
    who = params['uid']
    if who.blank? || who == 'all'
      logger.warn 'Will warm cache for all users'
      HotPlate.request_warmups_for_all
    else
      begin
        uid = Integer(who, 10)
      rescue ArgumentError
        raise Errors::BadRequestError, "Bad UID parameter '#{who}'"
      end
      logger.warn "Will warm cache for user #{uid}"
      HotPlate.request_warmup uid
    end
    render :json => {warmed: true}
  end

  private

  def check_permission
    authorize(current_user, :can_clear_cache?)
  end
end
