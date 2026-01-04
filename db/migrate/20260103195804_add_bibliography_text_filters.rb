# frozen_string_literal: true

class AddBibliographyTextFilters < ActiveRecord::Migration[8.0]
  def up
    TextFilter.find_or_create_by!(name: 'markdown bibliography') do |tf|
      tf.description = 'Markdown with Bibliography references'
      tf.markup = 'markdown'
      tf.filters = [:bibliography]
    end

    TextFilter.find_or_create_by!(name: 'markdown smartypants bibliography') do |tf|
      tf.description = 'Markdown with Smartypants and Bibliography'
      tf.markup = 'markdown'
      tf.filters = %i[smartypants bibliography]
    end
  end

  def down
    TextFilter.where(name: ['markdown bibliography', 'markdown smartypants bibliography']).destroy_all
  end
end
