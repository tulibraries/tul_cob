class UsersController < ApplicationController
  def loans
    @items = [
      {
        title: "History",
        due_date: "2014-06-23T14:00:00.000Z",
        item_barcode: "000237055710000121"
      }
    ]
  end

  def holds
    @items = [
      {
        title: "History",
        due_date: "2014-06-23T14:00:00.000Z",
      }
    ]
  end

  def fines
    @items = [
      {
        title: "History",
        amount: 2.25,
        due_date: "2014-06-23T14:00:00.000Z",
        payment_url: "http://example.com/pay_fines"
      }
    ]
  end
end
