# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit

  NOT_FOUND_ERROR_CLASSES = [
    ActionController::RoutingError,
    ActionController::UrlGenerationError,
    ActiveRecord::RecordNotFound,
    ActionView::MissingTemplate
  ].freeze

  protect_from_forgery with: :exception

  before_action :authenticate_user!
  before_action :set_raven_context

  respond_to :html, :json, :js
  rescue_from Exception, with: :render_error

  def authenticate_admin!
    current_user.is_admin? || not_found
  end

  ## Devise overrides
  # See also RegistrationsController::after_sign_up_path_for
  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || diagnoses_path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  def not_found
    raise ActionController::RoutingError, 'Not Found'
  end

  def current_expert
    Expert.find_by(access_token: params[:access_token])
  end

  def current_roles
    current_roles = [current_user]
    current_roles += current_user&.experts || []
    current_roles += [current_expert]
    current_roles.compact
  end

  def authenticate_expert!
    current_expert.present? || not_found
  end

  ## Configuration for honeypot-captcha
  #
  def honeypot_fields
    { :commentaire => 'Laissez ce champ vide !' }
  end

  def pundit_user
    UserContext.new(current_user, current_expert)
  end

  private

  def render_error(exception)
    raise exception if Rails.env.development? || (Rails.env.test? && !ENV['TEST_ERROR_RENDERING'].to_b)
    if NOT_FOUND_ERROR_CLASSES.include? exception.class
      respond_with_status(404)
    else
      Raven.capture_exception(exception)
      respond_with_status(500)
    end
  end

  def set_raven_context
    Raven.user_context(
      username: current_user&.full_name,
      email: current_user&.email,
      id: current_user&.id,
      ip_address: request.ip
    )
    Raven.extra_context(
      params: params.to_unsafe_h,
      url: request.url
    )
  end

  def respond_with_status(status)
    respond_with do |format|
      format.html { render "errors/#{status}" }
      format.json { render body: nil, status: status }
      format.js { render body: nil, status: status }
    end
  end

  def check_current_user_access_to(resource)
    http_method = request.request_method
    access_method = if %w[GET HEAD].include?(http_method)
      :can_be_viewed_by?
    elsif %w[PATCH POST PUT DELETE].include?(http_method)
      :can_be_modified_by?
    end

    if current_roles.any? { |role| resource.send(access_method, role) }
      return
    end
    # can not be viewed:
    not_found
  end
end
