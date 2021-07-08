module  Annuaire
  class AntennesController < BaseController
    def index
      @antennes = @institution.antennes
        .not_deleted
        .order(:name)
        .preload(:communes)

      @subjects_with_no_one = @institution.antennes_with_subject_with_no_one

      respond_to do |format|
        format.html
        format.csv do
          result = @antennes.export_csv
          send_data result.csv, type: 'text/csv; charset=utf-8', disposition: "attachment; filename=#{result.filename}.csv"
        end
      end
    end

    def import; end

    def import_create
      @result = Antenne.import_csv(params.require(:file), institution: @institution)
      if @result.success?
        flash[:table_highlighted_ids] = @result.objects.map(&:id)
        redirect_to action: :index
      else
        render :import
      end
    end
  end
end
