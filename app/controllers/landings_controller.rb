class LandingsController < PagesController
  def index
    @landings = Rails.cache.fetch('landings', expires_in: 3.minutes) do
      Landing.ordered_for_home.to_a
    end
    @tracking_params = info_params
  end

  def show
    @landing = retrieve_landing
    if @landing.nil?
      redirect_to root_path
      return
    end

    @landing_topics = @landing.landing_topics.ordered_for_landing
    @landing_options = @landing.landing_options.ordered_for_landing

    @tracking_params = info_params
    @solicitation = Solicitation.new(landing: @landing)
    @solicitation.form_info = info_params
  end

  def create_solicitation
    @solicitation = Solicitation.create(solicitation_params)
    @landing = Landing.find_by(slug: @solicitation.slug)

    if !@solicitation.valid?
      @result = 'failure'
      @partial = 'form'
      flash.alert = @solicitation.errors.full_messages.to_sentence
      return
    end

    @result = 'success'
    @partial = 'thank_you'
    CompanyMailer.confirmation_solicitation(@solicitation.email).deliver_later
    if ENV['FEATURE_SEND_ADMIN_SOLICITATION_EMAIL'].to_b
      AdminMailer.solicitation(@solicitation).deliver_later
    end

    respond_to do |format|
      format.html { redirect_to landing_path(@solicitation.landing, anchor: 'section-formulaire'), notice: t('.thanks') }
      format.js
    end
  end

  private

  def retrieve_landing
    slug = params[:slug]&.to_sym
    Rails.cache.fetch("landing-#{slug}", expires_in: 1.minute) do
      Landing.find_by(slug: slug)
    end
  end

  def show_params
    params.permit(:slug, *Solicitation::FORM_INFO_KEYS)
  end

  def info_params
    show_params.slice(*Solicitation::FORM_INFO_KEYS)
  end

  def solicitation_params
    params.require(:solicitation)
      .permit(:description, :siret, :full_name, :phone_number, :email, :slug, form_info: {}, options: {})
  end
end
