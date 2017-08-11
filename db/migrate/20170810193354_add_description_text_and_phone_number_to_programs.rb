class AddDescriptionTextAndPhoneNumberToPrograms < ActiveRecord::Migration
  def change
    add_column :programs_kpccprogram, :description_text, :text
    add_column :programs_kpccprogram, :phone_number,     :string
    add_column :external_programs,    :description_text, :text
    add_column :external_programs,    :phone_number,     :string
  end
end
