# frozen_string_literal: true

class AdminMailersService
  attr_accessor :information_hash, :not_admin_visits, :not_admin_diagnoses, :completed_diagnoses

  class << self
    def send_statistics_email
      AdminMailer.weekly_statistics(public_stats_counts, reminders_counts).deliver_later
    end

    private

    def public_stats_counts
      params = {
        start_date: 1.week.ago.to_date,
        end_date: Date.today
      }
      stats = Stats::Stats.new(params)
      counts = %i[solicitations solicitations_diagnoses exchange_with_expert taking_care].index_with do |name|
        stats.send(name).count
      end

      { params: params, counts: counts }
    end

    def reminders_counts
      counts = %i[poke recall warn archive].index_with do |name|
        Need.reminders_to(name).human_count
      end

      { counts: counts }
    end

    def sign_up_statistics
      recently_signed_up_users = User.created_last_week
      @information_hash[:signed_up_users] = {}
      @information_hash[:signed_up_users][:count] = recently_signed_up_users.count
      @information_hash[:signed_up_users][:items] = recently_signed_up_users.to_a
    end

    def created_diagnoses_statistics
      created_diagnoses = @not_admin_diagnoses.in_progress.created_last_week
      @information_hash[:created_diagnoses] = {}
      @information_hash[:created_diagnoses][:count] = created_diagnoses.count
      @information_hash[:created_diagnoses][:items] = created_diagnoses.to_a
    end

    def updated_diagnoses_statistics
      updated_diagnoses = @not_admin_diagnoses.in_progress.updated_last_week
      updated_diagnoses = updated_diagnoses.where('diagnoses.created_at < ?', 1.week.ago)
      @information_hash[:updated_diagnoses] = {}
      @information_hash[:updated_diagnoses][:count] = updated_diagnoses.count
      @information_hash[:updated_diagnoses][:items] = updated_diagnoses.to_a
    end

    def completed_diagnoses_statistics
      @information_hash[:completed_diagnoses] = {}
      @information_hash[:completed_diagnoses][:count] = @completed_diagnoses.count
      @information_hash[:completed_diagnoses][:items] = @completed_diagnoses.to_a
    end

    def matches_count_statistics
      matches_count = Match.joins(:need).where(needs: { diagnosis: @completed_diagnoses }).count
      @information_hash[:matches_count] = matches_count
    end

    def abandoned_needs_statistics
      scopes = %i[abandoned_quo_not_taken abandoned_taken_not_done rejected]
      scopes.each do |scope|
        @information_hash[scope] = Need.send(scope).count
      end
    end
  end
end
