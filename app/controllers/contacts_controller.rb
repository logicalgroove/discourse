require_dependency 'rate_limiter'

class ContactsController < ApplicationController
  skip_before_action :redirect_to_login_if_required
  skip_before_action :check_xhr
  skip_after_action  :perform_refresh_session
  skip_before_action :verify_authenticity_token
  before_action :ensure_logged_in, only: [:live_post_counts]

  def index
    respond_to do |format|
      format.html do
        flash[:notice] = flash[:notice]
        render :index
      end
      format.json do
        render_json_dump({message: flash[:notice]})
      end
    end
  end

  def create
    if params[:message] && params[:email]
      ContactsMailer.contact_us(params).deliver_now
      flash[:notice] = I18n.t('contact_success_message')
    end
    redirect_to contacts_path
  end
end
