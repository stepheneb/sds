class AddTrialGoalsToModelActivityData < ActiveRecord::Migration
  def self.up
    add_column "pas_model_activity_modelruns", :trial_number, :integer
    add_column "pas_model_activity_modelruns", :trial_goal, :text
  end

  def self.down
    remove_column "pas_model_activity_modelruns", :trial_number
    remove_column "pas_model_activity_modelruns", :trial_goal
  end
end
