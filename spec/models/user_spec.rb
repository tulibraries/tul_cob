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

    let(:patron_account) { FactoryGirl.build(:user) }
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

    it "has an UID" do
      expect(patron_account).to have_attribute(:uid)
    end

    it "shows items borrowed" do
      allow(Alma::User).to receive(:get_loans).and_return(double(:list => loans))
      items = patron_account.get_loans_list
      expect(items.sort).to match(loans.sort)
    end

    it "shows items requested" do
      allow(Alma::User).to receive(:get_requests).and_return(double(:list => holds))
      items = patron_account.get_holds_list
      expect(items.sort).to match(holds.sort)
    end

    it "shows fines owed" do
      allow(Alma::User).to receive(:get_fines).and_return(double(:list => fines))
      items = patron_account.get_fines_list
      expect(items.sort).to match(fines.sort)
    end

  end

  describe "Authentication services" do
    it "creates a valid omniauth user"
    it "authenticates an authorized user"
    it "fails to authenticates an unauthorized user"
    it "creates a session"
  end

end
