class AddIndentParagraphsToContents < ActiveRecord::Migration[8.0]
  def change
    add_column :contents, :indent_paragraphs, :boolean, default: false
  end
end
