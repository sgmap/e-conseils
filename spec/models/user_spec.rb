# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it do
      is_expected.to have_many :territory_users
      is_expected.to have_many :territories
    end
  end

  describe 'validations' do
    describe 'presence' do
      it do
        is_expected.to validate_presence_of(:first_name)
        is_expected.to validate_presence_of(:last_name)
        is_expected.to validate_presence_of(:role)
        is_expected.to validate_presence_of(:phone_number)
      end
    end

    describe 'emails' do
      it do
        is_expected.to validate_presence_of(:email)
        is_expected.to allow_value('test@beta.gouv.fr').for(:email)
        is_expected.not_to allow_value('test').for(:email)
      end
    end

    describe 'passwords' do
      it do
        is_expected.to validate_presence_of(:password)
        is_expected.not_to allow_value('short').for(:password)
      end
    end
  end

  describe 'scopes' do
    describe 'with_contact_page_order' do
      it do
        create :user, contact_page_order: nil
        user_of_contact_page = create :user, contact_page_order: 1

        expect(User.with_contact_page_order).to eq [user_of_contact_page]
      end
    end

    describe 'administrator_of_territory' do
      it do
        user1 = create :user, first_name:'bb', last_name:'bb'
        create :territory_user, user: user1
        user2 = create :user, first_name:'aa', last_name:'aa'
        create :territory_user, user: user2
        user3 = create :user, contact_page_order: 2
        create :territory_user, user: user3

        expect(User.administrators_of_territory).to eq [user2, user1]
      end
    end

    describe 'not_admin' do
      it do
        create :user, is_admin: true
        regular_user = create :user, is_admin: false

        expect(User.not_admin).to eq [regular_user]
      end
    end
  end

  describe 'full_name' do
    let(:user) { build :user, first_name: 'Ivan', last_name: 'Collombet' }

    it { expect(user.full_name).to eq 'Ivan Collombet' }
  end

  describe 'full_name_with_role' do
    let(:user) do
      build :user,
            first_name: 'Ivan',
            last_name: 'Collombet',
            role: 'Business Developer',
            institution: 'DINSIC'
    end

    it { expect(user.full_name_with_role).to eq 'Ivan Collombet, Business Developer, DINSIC' }
  end

  describe '#auto_approve_if_whitelisted_domain callback' do
    subject { user.is_approved? }

    let(:user) { create(:user, :just_registered, email: email) }

    context 'with an unkown email domain' do
      let(:email) { 'user@example.com' }

      it { is_expected.to be_falsey }
    end

    context 'with a kown email domain' do
      let(:email) { 'user@beta.gouv.fr' }

      it { is_expected.to be_truthy }
    end
  end
end
