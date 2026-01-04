# frozen_string_literal: true

# Monkey patch to handle ActionController::Parameters in attributes=
# This is needed for backward compatibility with Rails 3 code that uses
# model.attributes = params[:model]
module ActiveModel
  module ForbiddenAttributesProtection
    def sanitize_for_mass_assignment(attributes)
      # Convert ActionController::Parameters to hash
      if attributes.respond_to?(:to_unsafe_h)
        attributes.to_unsafe_h
      elsif attributes.respond_to?(:permitted?)
        attributes.permitted? ? attributes.to_h : raise(ActiveModel::ForbiddenAttributesError)
      else
        attributes
      end
    end
  end
end
