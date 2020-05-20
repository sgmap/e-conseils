class Diagnoses::StepsController < ApplicationController
  before_action :retrieve_diagnosis

  def needs
    @themes = Theme.ordered_for_interview

    @diagnosis.prepare_needs_from_solicitation
  end

  def update_needs
    authorize @diagnosis, :update?

    diagnosis_params = params_for_needs
    diagnosis_params[:step] = :visit
    if @diagnosis.update(diagnosis_params)
      redirect_to action: :visit
    else
      flash.alert = @diagnosis.errors.full_messages.to_sentence
      redirect_to action: :needs
    end
  end

  def visit
    @diagnosis.prepare_happened_on_from_solicitation
    @diagnosis.prepare_visitee_from_solicitation
  end

  def update_visit
    authorize @diagnosis, :update?

    diagnosis_params = params_for_visit
    diagnosis_params[:visitee_attributes][:company_id] = @diagnosis.facility.company.id
    diagnosis_params[:step] = :matches
    visitee = Contact.find_by(id: params[:diagnosis][:visitee_attributes][:id]) || Contact.new
    visitee_params = params.require(:diagnosis).permit(visitee_attributes: [:full_name, :role, :email, :phone_number])[:visitee_attributes]
    visitee.update(visitee_params)
    @diagnosis.visitee = visitee

    if @diagnosis.update(diagnosis_params)
      redirect_to action: :matches
    else
      flash.alert = @diagnosis.errors.full_messages.to_sentence
      redirect_to action: :visit
    end
  end

  def matches
    @diagnosis.prepare_matches_from_solicitation
  end

  def update_matches
    authorize @diagnosis, :update?

    diagnosis_params = params_for_matches
    diagnosis_params[:step] = :completed

    if @diagnosis.update(diagnosis_params)
      @diagnosis.notify_matches_made!
      @diagnosis.solicitation&.status_processed!
      flash.notice = I18n.t('diagnoses.steps.matches.notifications_sent')
      redirect_to need_path(@diagnosis)
    else
      flash.alert = @diagnosis.errors.full_messages.to_sentence
      redirect_to action: :matches
    end
  end

  private

  def retrieve_diagnosis
    @diagnosis = Diagnosis.find(params.require(:id))
  end

  def params_for_needs
    params.require(:diagnosis)
      .permit(:content, needs_attributes: [:_destroy, :content, :subject_id, :id])
  end

  def params_for_visit
    params.require(:diagnosis)
      .permit(:happened_on,
              visitee_attributes: [:full_name, :role, :email, :phone_number, :id],
              facility_attributes: [:insee_code, :id])
  end

  def params_for_matches
    params.require(:diagnosis)
      .permit(needs_attributes: [:id, matches_attributes: [:_destroy, :id, :subject_id, :expert_id]])
  end
end
