# == Schema Information
#
# Table name: institutions
#
#  id              :bigint(8)        not null, primary key
#  code_region     :integer
#  deleted_at      :datetime
#  logo_sort_order :integer
#  name            :string           not null
#  show_on_list    :boolean          default(FALSE)
#  slug            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_institutions_on_code_region  (code_region)
#  index_institutions_on_deleted_at   (deleted_at)
#  index_institutions_on_name         (name) UNIQUE
#  index_institutions_on_slug         (slug) UNIQUE
#  index_institutions_on_updated_at   (updated_at)
#

class Institution < ApplicationRecord
  include SoftDeletable

  ## Associations
  #
  has_many :antennes, -> { not_deleted }, inverse_of: :institution
  has_many :institutions_subjects, inverse_of: :institution
  has_many :landings, inverse_of: :institution
  has_many :solicitations, inverse_of: :institution

  ## Hooks and Validations
  #
  auto_strip_attributes :name
  validates :name, :slug, presence: true, uniqueness: true
  before_validation :compute_slug

  ## Through Associations
  #
  # :institutions_subjects
  has_many :subjects, through: :institutions_subjects, inverse_of: :institutions, dependent: :destroy
  has_many :themes, through: :institutions_subjects, inverse_of: :institutions

  # :antennes
  has_many :experts, through: :antennes, inverse_of: :institution
  has_many :advisors, through: :antennes, inverse_of: :institution
  has_many :sent_diagnoses, through: :antennes, inverse_of: :advisor_institution
  has_many :sent_needs, through: :antennes, inverse_of: :advisor_institution
  has_many :sent_matches, through: :antennes, inverse_of: :advisor_institution

  has_many :received_matches, through: :antennes, inverse_of: :expert_institution
  has_many :received_needs, through: :antennes, inverse_of: :expert_institutions
  has_many :received_diagnoses, through: :antennes, inverse_of: :expert_institutions
  has_many :received_solicitations, through: :received_diagnoses, source: :solicitation, inverse_of: :diagnosis

  # Same as :advisors and :antennes, but excluding deleted items; this makes it possible to preload not_deleted items in views.
  has_many :not_deleted_antennes, -> { not_deleted }, class_name: "Antenne", inverse_of: :institution
  has_many :advisors, through: :antennes, inverse_of: :institution

  accepts_nested_attributes_for :institutions_subjects, :allow_destroy => true

  ## Scopes
  #
  scope :ordered_logos, -> { not_deleted.where.not(logo_sort_order: nil).order(:logo_sort_order) }

  ## Institution subjects helpers
  #

  # All the subjects that can be assigned to an expert of this institution
  def available_subjects
    institutions_subjects
      .ordered_for_interview
      .includes(:theme)
      .merge(Subject.archived(false))
      .group_by { |is| is.theme } # Enumerable#group_by maintains ordering
  end

  ##
  #
  def to_param
    slug
  end

  def to_s
    name
  end

  def compute_slug
    if name.present?
      self.slug = name.parameterize.underscore
    end
  end

  def antennes_with_subject_with_no_one
    result = {}
    antennes.each do |antenne|
      institutions_subjects.each do |i_subject|
        experts_subjects = ExpertSubject.where(institution_subject: i_subject, expert: [antenne.experts])
        # des fois ça ne trouve personne alors qu'il y a quelqu'un dans le tableau sur /annuaire/institutions/cci/conseillers
        # exemple pour l'antenne 152 de la CCI
        # institution subject 195
        # expert 382
        # le problème viens du tableau ou d'ici ?
        if experts_subjects.blank?
          result[antenne] ||= []
          result[antenne] << i_subject.subject
        end
      end
    end
    result
  end
end
