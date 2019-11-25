module Effectif
  extend ActiveSupport::Concern

  def effectif
    Effectif::effectif(self.code_effectif)
  end

  def self.effectif(code)
    if code.nil?
      return I18n.t('other')
    end

    I18n.t("codes_effectif.#{code}", default: I18n.t('other'))
  end
end
