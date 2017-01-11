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

  def loans
    item_loans = Alma.get_loans(alma_id)
  end

  def holds
    item_holds = Alma.get_holds(alma_id)
  end

  def fines
    item_fines = Alma.get_fines(alma_id)
  end
end
