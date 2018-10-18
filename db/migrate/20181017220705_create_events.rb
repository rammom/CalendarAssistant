class CreateEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :events do |t|
      t.string :name
      t.integer :weekly_occurrence
      t.integer :duration

      t.timestamps
    end
  end
end
