class CreateSleepRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :sleep_records do |t|
      t.references :user, null: false, foreign_key: true
      t.timestamp :start_time
      t.timestamp :end_time
      t.integer :duration

      t.timestamps
    end
  end
end
