# frozen_string_literal: true

class User < ApplicationRecord
  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :email, :password, :password_confirmation
  end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :omniauthable, omniauth_providers: [:shibboleth]

  def alma
    @alma ||= Alma::User.find(uid)
  end

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.

  def to_s
    email
  end

  def loans
    Alma::Loan.where_user(uid, order_by: "due_date")
  end

  def fines
    Alma::Fine.where_user(uid)
  end

  def holds
    Alma::UserRequest.where_user(uid)
  end

  def renew_selected(ids)
    Alma::User.send_multiple_loan_renewal_requests(user_id: uid, loan_ids: ids)
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.uid        = auth.uid
      user.provider   = auth.provider
      user.email      = (auth.info.email || "#{auth.uid}@temple.edu")
      user.name       = auth.info.name
      user.last_name  = auth.info.last_name
      user.first_name = auth.info.first_name
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.alma_data"] && session["devise.alma_data"]["extra"]["raw_info"]
        user.uid = data["uid"] if user.uid.blank?
      end
    end
  end

  # Overridden because we do not want to limit bookmark selection to one document type.
  def bookmarks_for_documents(documents = [])
    if documents.any?
      bookmarks.where(document_id: documents.map(&:id))
    else
      []
    end
  end
end
