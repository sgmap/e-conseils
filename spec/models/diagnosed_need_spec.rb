# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiagnosedNeed, type: :model do
  describe 'validations' do
    it do
      is_expected.to belong_to :diagnosis
      is_expected.to belong_to :question
      is_expected.to have_many :selected_assistance_experts
      is_expected.to validate_presence_of(:diagnosis)
    end
  end

  describe 'scopes' do
    describe 'of_diagnosis' do
      subject { DiagnosedNeed.of_diagnosis diagnosis }

      let(:diagnosis) { create :diagnosis }
      let(:diagnosed_need) { create :diagnosed_need, diagnosis: diagnosis }

      it { is_expected.to eq [diagnosed_need] }
    end

    describe 'of_assistance_expert_id' do
      subject { DiagnosedNeed.of_assistance_expert_id assistance_expert.id }

      let(:question) { create :question }
      let(:assistance) { create :assistance, question: question }
      let(:assistance_expert) { create :assistance_expert, assistance: assistance }
      let(:diagnosed_need) { create :diagnosed_need, question: question }

      it { is_expected.to eq [diagnosed_need] }
    end
  end
end
