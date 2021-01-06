module Stats::Mini
  class CompaniesByEmployeesStats
    include ::Stats::BaseStats

    def main_query
      Company
        .includes(:needs).references(:needs)
        .where(facilities: { diagnoses: { step: :completed } })
        .distinct
    end
  end
end
