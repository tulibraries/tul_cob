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

    let(:patron_account) { FactoryBot.build(:user) }
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
      items = patron_account.get_loans
      expect(items.list.sort).to match(loans.sort)
    end

    it "shows items requested" do
      allow(Alma::User).to receive(:get_requests).and_return(double(:list => holds))
      items = patron_account.get_holds
      expect(items.list.sort).to match(holds.sort)
    end

    it "shows fines owed" do
      allow(Alma::User).to receive(:get_fines).and_return(double(:list => fines))
      items = patron_account.get_fines
      expect(items.list.sort).to match(fines.sort)
    end

  end

  describe "Authentication services" do
    let(:new_user) { FactoryBot.build(:user) }
    let(:authorized_user) { User.from_omniauth(new_user) }

    it "creates a valid omniauth user" do
      expect(authorized_user.email).to match("#{new_user.uid}@temple.edu")
      expect(authorized_user.uid).to match(new_user.uid)
      expect(authorized_user.provider).to match(new_user.provider)
      expect(authorized_user.id).to be
    end

    it "shows the user string as the email address" do
      expect(authorized_user.to_s).to match(authorized_user.email)
    end
  end

end
