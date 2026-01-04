# frozen_string_literal: true

class Categorization < ActiveRecord::Base
  belongs_to :article, optional: true
  belongs_to :category, optional: true
end
