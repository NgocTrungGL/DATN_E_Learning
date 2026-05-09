class CreateSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.integer :plan_type, null: false, default: 0
      t.string :status, null: false, default: "active"
      t.string :stripe_subscription_id, index: true
      t.string :stripe_customer_id
      t.datetime :current_period_start
      t.datetime :current_period_end

      t.timestamps
    end
  end
end
