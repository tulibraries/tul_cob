User Interaction With Alma
===

To have Blacklight display information about a user, we are going to extend the Devise User model to include behaviors.

To start, we will mock the response directly in the methods until we can drop in an API:

Add two methods to the User model:
* `items_on_loan`
* `fines`

Both should return a struct/object that responds to `total_results` for the number of results and `list` for a list of the results.

`items_on_loan.list` returns a list of `Item` Objects. 

`Item` should respond to
* `title`
* `due_date`
* `barcode`


`fines.list` should return a list of `Fine` objects.

`Fine` should respond to:
* `title` of the item that caused the fine
* `barcode` of the item that caused the fine
* `amount` The fine / fee balance.
* `creation_time` Date the fine / fee was created.
* `comment` Fine / fee comment.

`fines.sum` should respond with the total amount of all fines owed.
