class Redirection < ActiveRecord::Base
  belongs_to :content, optional: true
  belongs_to :redirect, optional: true
end
