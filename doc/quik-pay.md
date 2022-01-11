QuikPay (Pay Online) Feature
===

This feature allows designated authenticated users to be able to pay fines and fees online with their TUPay account.

The feature is comprised of the following components:

## Routes
The named routes `quik_pay`, and `quik_pay_callback` are defined. They each are routed to an action by the same name.

## Actions
Two new controller actions are defined, `quik_pay` and `quik_pay_callback`

### quik_pay
The `quik_pay` action redirects a valid and authenticated user to the online payment service along with a timeStamp and validation hash required by the quikPay service.

The approach of using this redirection technique is to avoid creating timeStamps that become stale if a user lingers on a page where a URL to the online payment service is already predefined.

It is important to note that the quikpay service URL that users are redirected to is a contract in terms of the parameters that are sent and the order that they appear in the URL. Any deviation from this contract breaks the application because the validation hash generated at the service end depends on these known parameters with their known order.

### quik_pay_callback
When a user is done paying via the online payment service they will be redirected back to the `quik_pay_callback` route on our app where this action will validate that the callback is both valid and then will wipe the user's fines from their alma records before redirecting them back to the user account page.

## Helpers
A `quik_pay_button` helper method is defined. It generates a "Pay Online" button link if and only if the current user is allowed to pay online.

## User methods
`User#can_pay_online?` is defined now on the `User` model in order to be able to declaratively check if a user can pay online.

## Session values
Two new session values are defined when a user visits their account page: `session["can_pay_online?"]` and `session["total_fines"]`. This is done in order to avoid having to make extra an call to the Alma API from the `quik_pay` action.

