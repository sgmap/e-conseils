# frozen_string_literal: true

class DiagnosesController < ApplicationController
  def index
    @diagnoses_count = Diagnosis.of_user(current_user).count
    in_progress_associations = [visit: [facility: [:company]]]
    @diagnoses_in_progress = Diagnosis.of_user(current_user)
                               .in_progress.reverse_chronological
                               .joins(in_progress_associations)
                               .includes(in_progress_associations)
    completed_associations = [{ visit: [{ facility: [:company] }, :visitee] }]
    completed_associations_outer_join = [{ diagnosed_needs: [:selected_assistance_experts] }]
    @diagnoses_completed = Diagnosis.of_user(current_user)
                             .completed.reverse_chronological
                             .joins(completed_associations)
                             .includes(completed_associations)
  end

  def step1;
  end

  def step2
    @diagnosis = Diagnosis.find params[:id]
  end

  def step3
    associations = [visit: [facility: [:company]]]
    @diagnosis = Diagnosis.joins(associations)
                   .includes(associations)
                   .find params[:id]
  end

  def step4
    @diagnosis = Diagnosis.find params[:id]
    @diagnosed_needs = DiagnosedNeed.of_diagnosis(@diagnosis)
    associations = [question: [assistances: [assistances_experts: [expert: :institution]]]]
    @diagnosed_needs = @diagnosed_needs.joins(associations).includes(associations)
  end

  def step5
    associations = [visit: [facility: [:company]], diagnosed_needs: [:selected_assistance_experts]]
    @diagnosis = Diagnosis.left_outer_joins(associations)
                   .includes(associations)
                   .find params[:id]
  end

  def notify_experts
    diagnosis = Diagnosis.find params[:id]
    assistance_expert_ids = ExpertMailersService.filter_assistances_experts(params[:assistances_experts])
    UseCases::CreateSelectedAssistancesExperts.perform(diagnosis, assistance_expert_ids)
    # TODO: Use Delayed Jobs to perform email sending ; http://doc.scalingo.com/languages/ruby/delayed-job.html
    ExpertMailersService.send_assistances_email(advisor: current_user, diagnosis: diagnosis,
                                                assistance_expert_ids: assistance_expert_ids)
    diagnosis.update step: 5
    redirect_to step_5_diagnosis_path(diagnosis)
  end

  # Former action

  def show
    @visit = Visit.of_advisor(current_user).includes(facility: :company).find params[:visit_id]
    @diagnosis = Diagnosis.of_visit(@visit)
                   .includes(diagnosed_needs: [:question])
                   .find params[:id]
  end
end
