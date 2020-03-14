# == Schema Information
#
# Table name: solicitations
#
#  id           :bigint(8)        not null, primary key
#  description  :string
#  email        :string
#  form_info    :jsonb
#  full_name    :string
#  needs        :jsonb
#  phone_number :string
#  siret        :string
#  status       :integer          default("in_progress")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Solicitation < ApplicationRecord
  enum status: { in_progress: 0, processed: 1, canceled: 2 }, _prefix: true

  ## Associations
  #
  has_many :diagnoses

  ## Validations
  #
  validates :email, format: { with: Devise.email_regexp }, allow_blank: true

  ## “Through” Associations
  #

  ## Scopes
  #
  default_scope { order(updated_at: :desc) }
  scope :of_campaign, -> (campaign) { where("form_info->>'pk_campaign' = ?", campaign) }
  scope :of_slug, -> (slug) { where("form_info->>'slug' = ?", slug) }

  ## JSON Accessors
  #
  FORM_INFO_KEYS = %i[slug partner_token pk_campaign pk_kwd gclid]
  store_accessor :form_info, FORM_INFO_KEYS.map(&:to_s)

  ## ActiveAdmin/Ransacker helpers
  #
  FORM_INFO_KEYS.each do |key|
    ransacker key do |parent|
      Arel::Nodes::InfixOperation.new('->>', parent.table[:form_info], Arel::Nodes.build_quoted(key.to_s))
    end
  end

  ##
  #
  def institution
    Institution.find_by(partner_token: partner_token) if partner_token.present?
  end

  def normalized_phone_number
    number = phone_number&.gsub(/[^0-9]/,'')
    if number.present? && number.length == 10
      number.gsub(/(.{2})(?=.)/, '\1 \2')
    else
      phone_number
    end
  end

  def to_s
    "#{self.class.model_name.human} #{id}"
  end

  def display_attributes
    %i[siret email phone_number institution pk_campaign pk_kwd slug]
  end
end
