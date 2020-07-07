# == Schema Information
#
# Table name: landing_topics
#
#  id                  :bigint(8)        not null, primary key
#  description         :text
#  landing_option_slug :string
#  landing_sort_order  :integer
#  title               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  landing_id          :bigint(8)        not null
#
# Indexes
#
#  index_landing_topics_on_landing_id  (landing_id)
#
# Foreign Keys
#
#  fk_rails_...  (landing_id => landings.id)
#

class LandingTopic < ApplicationRecord
  belongs_to :landing, inverse_of: :landing_topics, touch: true

  scope :ordered_for_landing, -> { order(:landing_sort_order, :id) }
end
