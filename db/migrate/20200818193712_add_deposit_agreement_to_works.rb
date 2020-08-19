class AddDepositAgreementToWorks < ActiveRecord::Migration[6.0]
  def change
    add_column :works, :deposit_agreement_version, :string
    add_column :works, :deposit_agreed_at, :datetime
  end
end
