# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Institution, type: :model do
  it do
    is_expected.to have_many :experts
    is_expected.to validate_presence_of :name
  end

  describe 'relations' do
    describe 'antenne' do
      let(:active_antenne) { create :antenne }
      let(:deleted_antenne) { create :antenne, deleted_at: Time.now }
      let(:institution) { create :institution, antennes: [active_antenne, deleted_antenne] }

      subject { institution.antennes }

      before { institution.reload }

      it 'return only not deleted antennes' do
        is_expected.to match [active_antenne]
      end
    end
  end

  describe 'to_s' do
    it do
      institution = create :institution, name: 'Direccte'
      expect(institution.to_s).to eq 'Direccte'
    end
  end

  describe 'compute_slug' do
    let(:institution) { build :institution, name: "My Institution" }

    context 'manual call' do
      before { institution.compute_slug }

      it { expect(institution.slug).to eq 'my_institution' }
    end

    context 'before_validation hook' do
      before { institution.save }

      it do
        expect(institution.slug).to eq 'my_institution'
        expect(institution).to be_valid
      end
    end
  end

  describe 'antennes_with_subject_with_no_one' do
    let(:institution) { create :institution }
    let!(:antenne) { create :antenne, institution: institution }

    # ça fonctionne pas si je mets 'is_expected machin' mais je ne sais pas pourquoi
    subject { institution.antennes_with_subject_with_no_one }

    context 'antenne avec un sujet qui a des experts KO' do
      let!(:subject) { create :subject }
      let!(:expert) { create :expert_with_users, antenne: antenne }
      let!(:institution_subject) { create :institution_subject, institution: institution, subject: subject}
      let!(:expert_subject) { create :expert_subject, expert: expert, institution_subject: institution_subject}

      it 'return empty hash' do
        expect(institution.antennes_with_subject_with_no_one).to eq({})
      end
    end

    context 'antenne avec un sujet qui n’a pas d’expert OK' do
      let!(:subject) { create :subject }
      let!(:institution_subject) { create :institution_subject, institution: institution, subject: subject}

      it 'return hash with antennes and subjects' do
        expect(institution.antennes_with_subject_with_no_one).to eq({ antenne => [subject] })
      end
    end

    context 'antenne avec 3 sujets sujets dont deux sans expert OK' do
      let!(:expert) { create :expert_with_users, antenne: antenne }
      let!(:subject_1) { create :subject }
      let!(:subject_2) { create :subject }
      let!(:subject_3) { create :subject }
      let!(:institution_subject_1) { create :institution_subject, institution: institution, subject: subject_1}
      let!(:institution_subject_2) { create :institution_subject, institution: institution, subject: subject_2}
      let!(:institution_subject_3) { create :institution_subject, institution: institution, subject: subject_3}
      let!(:expert_subject_1) { create :expert_subject, expert: expert, institution_subject: institution_subject_1}

      it 'return hash with antennes and subjects' do
        expect(institution.antennes_with_subject_with_no_one).to eq({ antenne => [subject_2, subject_3] })
      end
    end

    context 'antenne avec plusieurs sujets et tous avec un expert KO' do
      let(:institution) { create :institution }
      let!(:expert) { create :expert_with_users, antenne: antenne }
      let!(:subject_1) { create :subject }
      let!(:subject_2) { create :subject }
      let!(:institution_subject_1) { create :institution_subject, institution: institution, subject: subject_1}
      let!(:institution_subject_2) { create :institution_subject, institution: institution, subject: subject_2}
      let!(:expert_subject_1) { create :expert_subject, expert: expert, institution_subject: institution_subject_1}
      let!(:expert_subject_2) { create :expert_subject, expert: expert, institution_subject: institution_subject_2}

      it 'return empty hash' do
        expect(institution.antennes_with_subject_with_no_one).to eq({})
      end
    end
  end
end
