class CreateQuestions < ActiveRecord::Migration[7.1]
  def change
    create_table :questions do |t|
      t.string :question
      t.text :context
      t.text :answer
      t.integer :ask_count, default: 1

      t.timestamps
    end
  end
end
