module Annuaire
  class BaseController < ApplicationController
    before_action :retrieve_institution
    layout 'annuaire'

    def retrieve_institution
      @institution = Institution.find_by(slug: params[:institution_slug])
      authorize @institution
    end
  end
end
