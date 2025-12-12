class SplitBankInfoInPayoutRequests < ActiveRecord::Migration[7.0]
  def change
    remove_column :payout_requests, :bank_info, :text

    add_column :payout_requests, :bank_name, :string
    add_column :payout_requests, :bank_account_num, :string
    add_column :payout_requests, :bank_account_name, :string
  end
end
