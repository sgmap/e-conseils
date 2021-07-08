module  Annuaire
  class InstitutionsController < ApplicationController
    def index
      authorize Institution, :index?

      @institutions = Institution.not_deleted
        .order(:slug)
        .preload([institutions_subjects: :theme], :not_deleted_antennes, :advisors)

      @wide_layout = true
    end

    def show
      redirect_to institution_subjects_path(params[:slug])
    end
  end
end
