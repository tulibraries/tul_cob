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

    it "has an email address" do
      expect(patron_account).to have_attribute(:email)
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
    let(:new_user) { FactoryGirl.build(:user) }
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

  describe "User maintenance" do
    before :all do
      DatabaseCleaner.strategy = :truncation
    end

    after :all do
      DatabaseCleaner.clean
    end

    let(:details) {
      {
        primary_id: "History",
        user_title: {
          contact_info: {
            emails: {
              email_address: "guest@temple.edu"
            }
          }
        }
      }
    }
  end

  describe "Alma Cleanup" do
    let (:user_id) { "123456789" }
    let (:user) { Alma::User.find("123456789")}

    before(:each) {
      allow(Alma::User).to receive(:find).with(user_id) {
        filename = File.join(File.expand_path("../../fixtures", __FILE__), "user.json")
        Alma::User.new JSON.parse(File.read(filename))["response"]
      }

      allow(Alma::User).to receive(:users_base_path) {
        "https://api-eu.hosted.exlibrisgroup.com/almaws/v1/users"
      }
    }

    it "get the user's email address" do
      expect(user.email).to match("bilbo.baggins@hobbiton.edu")
    end

    describe '#expire' do
      let (:expired_email_address) { "blank@expired.temple.edu" }

      it 'changes the email address' do
        new_mail = user.update_email!(expired_email_address)
        expect(user.email).to match(expired_email_address)
      end
    end
  end

end
