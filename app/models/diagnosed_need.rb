# == Schema Information
#
# Table name: diagnosed_needs
#
#  id             :bigint(8)        not null, primary key
#  archived_at    :datetime
#  content        :text
#  matches_count  :integer
#  question_label :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  diagnosis_id   :bigint(8)
#  question_id    :bigint(8)
#
# Indexes
#
#  index_diagnosed_needs_on_archived_at   (archived_at)
#  index_diagnosed_needs_on_diagnosis_id  (diagnosis_id)
#  index_diagnosed_needs_on_question_id   (question_id)
#
# Foreign Keys
#
#  fk_rails_...  (diagnosis_id => diagnoses.id)
#  fk_rails_...  (question_id => questions.id)
#

class DiagnosedNeed < ApplicationRecord
  ## Associations
  #
  belongs_to :diagnosis, inverse_of: :diagnosed_needs
  belongs_to :question, inverse_of: :diagnosed_needs, optional: true # Orphaned diagnosed_needs are currently allowed in the DB. This leads to _bad data_, we might want to review that.
  has_many :matches, dependent: :destroy, inverse_of: :diagnosed_need

  ## Validations
  #
  validates :diagnosis, presence: true
  validates :question, uniqueness: { scope: :diagnosis_id, allow_nil: true }

  ##
  #
  before_create :copy_question_label

  ## Through Associations
  #
  # :diagnosis
  has_one :visit, through: :diagnosis # TODO: should be removed once we merge the Visit and Diagnosis models
  has_one :facility, through: :diagnosis, inverse_of: :diagnosed_needs
  has_one :company, through: :diagnosis, inverse_of: :diagnosed_needs
  has_one :advisor, through: :diagnosis, inverse_of: :sent_diagnosed_needs

  # :matches
  has_many :experts, through: :matches, inverse_of: :received_diagnosed_needs
  has_many :relays, through: :matches
  has_many :feedbacks, through: :matches, inverse_of: :diagnosed_need

  # :facility
  has_many :facility_territories, through: :facility, source: :territories, inverse_of: :diagnosed_needs

  # :advisor
  has_one :advisor_antenne, through: :advisor, source: :antenne, inverse_of: :sent_diagnosed_needs
  has_one :advisor_institution, through: :advisor, source: :antenne_institution, inverse_of: :sent_diagnosed_needs

  # :experts
  has_many :expert_antennes, through: :experts, source: :antenne, inverse_of: :received_diagnosed_needs
  has_many :expert_institutions, through: :experts, source: :antenne_institution, inverse_of: :received_diagnosed_needs

  ## Scopes
  #
  scope :of_relay_or_expert, (-> (relay_or_expert) { joins(:matches).merge(Match.of_relay_or_expert(relay_or_expert)) })

  scope :with_at_least_one_expert_done, -> { done }

  scope :unsent, -> { left_outer_joins(:matches).where('matches.id IS NULL').distinct }
  scope :with_no_one_in_charge, -> { joins(:matches).where.not(matches: Match.where(status: [:done, :taking_care])).distinct }
  scope :abandoned, -> { joins(:matches).where.not(matches: Match.where(status: [:quo, :done, :taking_care])).distinct }
  scope :being_taken_care_of, -> { where(matches: Match.where(status: [:taking_care])).where.not(id: done) }
  scope :done, -> { where(matches: Match.where(status: [:done])) }

  scope :made_in, (lambda do |date_range|
    joins(diagnosis: :visit)
      .where(diagnoses: { visits: { happened_on: date_range } })
      .distinct
  end)
  scope :ordered_by_interview, -> do
    left_outer_joins(:question, question: :category)
      .order('categories.interview_sort_order')
      .order('questions.interview_sort_order')
  end

  ##
  #
  def to_s
    "#{company} : #{question}"
  end

  def status_synthesis
    matches_status = matches.pluck(:status).map(&:to_sym)

    if matches_status.empty?
      :quo
    elsif matches_status.include?(:done)
      :done
    elsif matches_status.include?(:taking_care)
      :taking_care
    elsif matches_status.all?{ |o| o == :not_for_me }
      :not_for_me
    else
      :quo
    end
  end

  def status_description
    I18n.t("activerecord.attributes.match.statuses.#{status_synthesis}")
  end

  def status_short_description
    I18n.t("activerecord.attributes.match.statuses_short.#{status_synthesis}")
  end

  ##
  #
  def can_be_viewed_by?(role)
    diagnosis.visit.can_be_viewed_by?(role) || belongs_to_relay_or_expert?(role)
  end

  def belongs_to_relay_or_expert?(role)
    relays.include?(role) || experts.include?(role)
  end

  ##
  #
  def contacted_persons
    (relays.map(&:user) + experts).uniq
  end

  private

  def copy_question_label
    self.question_label ||= question&.label
  end
end
