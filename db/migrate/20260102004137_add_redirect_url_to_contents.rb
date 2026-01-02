class AddRedirectUrlToContents < ActiveRecord::Migration[8.0]
  def change
    add_column :contents, :redirect_url, :string
  end
end
