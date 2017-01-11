require 'rails_helper'
require 'database_cleaner'

RSpec.describe User, type: :model do
  describe "Alma services" do
    before :all do
      DatabaseCleaner.strategy = :truncation
    end

    after :all do
      DatabaseCleaner.clean
    end

    let(:patron_account_hash) { {email: "patron@example.edu",
                            password: "asdfjkl;",
                            password_confirmation: "asdfjkl;",
                            alma_id: "123456" } }
    let(:patron_account) { User.create!(patron_account_hash) }
    let(:loans) {
      [{
        title: "History",
        due_date: "2014-06-23T14:00:00.000Z",
        item_barcode: "000237055710000121"
      }]
    }
    let(:holds) {
      [{
        title: "History",
        due_date: "2014-06-23T14:00:00.000Z",
      }]
    }
    let(:fines) {
      [{
        title: "History",
        amount: 2.25,
        due_date: "2014-06-23T14:00:00.000Z",
        payment_url: "http://example.com/pay_fines"
      }]
    }

    it "has an Alma ID" do
      expect(patron_account).to have_attribute(:alma_id)
    end

    it "shows items borrowed" do
      allow(Alma).to receive(:get_loans).and_return(loans)
      items = patron_account.loans
      expect(items.sort).to match(loans.sort)
    end

    it "shows items requested" do
      allow(Alma).to receive(:get_holds).and_return(holds)
      items = patron_account.holds
      expect(items.sort).to match(holds.sort)
    end

    it "shows fines owed" do
      allow(Alma).to receive(:get_fines).and_return(fines)
      items = patron_account.fines
      expect(items.sort).to match(fines.sort)
    end

  end
end
