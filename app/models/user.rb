# frozen_string_literal: true

class User < ApplicationRecord
  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :email, :password, :password_confirmation
  end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :omniauthable, omniauth_providers: [:alma]

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  def get_loans
    item_loans = Alma::User.get_loans(user_id: uid, expand: "renewable")
  end

  def get_holds
    item_holds = Alma::User.get_requests(user_id: uid)
  end

  def get_fines
    item_fines = Alma::User.get_fines(user_id: uid)
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.uid      = auth.uid
      user.provider = auth.provider
      user.email    = "#{auth.uid}@temple.edu"
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.alma_data"] && session["devise.alma_data"]["extra"]["raw_info"]
        user.uid = data["uid"] if user.uid.blank?
      end
    end
  end
end
