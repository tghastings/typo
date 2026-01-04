# frozen_string_literal: true

class Profile < ActiveRecord::Base
  serialize :modules, coder: YAML
  validates_uniqueness_of :label

  ADMIN = 'admin'

  def modules
    read_attribute(:modules) || []
  end

  def modules=(perms)
    perms = perms.collect { |p| p.to_sym unless p.blank? }.compact if perms
    write_attribute(:modules, perms)
  end

  def project_modules
    modules.collect do |mod|
      AccessControl.project_module(label, mod)
    end.uniq.compact
  end
end
