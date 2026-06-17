class AddCancellationTrackingToSubscriptions < ActiveRecord::Migration[7.0]
  def change
    add_column :subscriptions, :cancel_at_period_end, :boolean, null: false, default: false
    add_column :subscriptions, :canceled_at, :datetime
  end
end
