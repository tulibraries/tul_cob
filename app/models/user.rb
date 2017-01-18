require 'alma_utils'

class User < ApplicationRecord

  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :email, :password, :password_confirmation
  end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  def get_loans_list
    item_loans = Alma::User.get_loans({user_id: alma_id}).list
  end

  def get_holds_list
    item_holds = Alma::User.get_holds({user_id: alma_id}).list
  end

  def get_fines_list
    item_fines = Alma::User.get_fines({user_id: alma_id}).list
  end
end
