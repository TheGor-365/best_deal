class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :name
      t.decimal :price
      t.string :link
      t.string :marketplace
      t.text :description
      t.text :characteristics

      t.timestamps
    end
  end
end
