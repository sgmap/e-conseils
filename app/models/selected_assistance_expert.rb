# frozen_string_literal: true

class SelectedAssistanceExpert < ApplicationRecord
  belongs_to :diagnosed_need
  belongs_to :assistance_expert, foreign_key: :assistances_experts_id

  validates :diagnosed_need, :assistance_expert, presence: true

  scope :not_viewed, (-> { where(expert_viewed_page_at: nil) })
  scope :of_expert, (->(expert) { joins(:assistance_expert).where(assistances_experts: { expert: expert }) })
  scope :of_diagnoses, (proc do |diagnoses|
    joins(diagnosed_need: :diagnosis).where(diagnosed_needs: { diagnosis: diagnoses })
  end)
end
