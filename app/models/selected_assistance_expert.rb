# frozen_string_literal: true

class SelectedAssistanceExpert < ApplicationRecord
  enum status: { quo: 0, taking_care: 1, done: 2, not_for_me: 3 }, _prefix: true

  belongs_to :diagnosed_need
  belongs_to :assistance_expert, foreign_key: :assistances_experts_id

  validates :diagnosed_need, :assistance_expert, presence: true

  scope :not_viewed, (-> { where(expert_viewed_page_at: nil) })
  scope :of_expert, (->(expert) { joins(:assistance_expert).where(assistances_experts: { expert: expert }) })
  scope :of_diagnoses, (lambda do |diagnoses|
    joins(diagnosed_need: :diagnosis).where(diagnosed_needs: { diagnosis: diagnoses })
  end)
  scope :with_status, (->(status) { where(status: status) })
  scope :created_before_one_week_ago, (-> { where('created_at < ?', 1.week.ago) })
  scope :needing_taking_care_update, (-> { with_status(:taking_care).created_before_one_week_ago })
  scope :with_no_one_in_charge, (lambda do
    ids = SelectedAssistanceExpert.select(:diagnosed_need_id).group(:diagnosed_need_id).having('SUM(status) = 0')
    where(diagnosed_need_id: ids)
  end)
end
