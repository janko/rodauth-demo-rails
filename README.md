# Rodauth Rails Demo

Example app that demonstrates how to integrate [Rodauth] into Rails. All
important Rails features work as expected:

* views are rendered with ActionController
* emails are sent with ActionMailer
* CSRF token is verified with ActionController
* flash messages are saved into ActionController

## Features

The following authentication features are implemented at the moment:

* Login
* Create Account
* Verify Account
* Reset Password
* Logout

## How it works

We create an [initializer] which defines an authentication middelware and adds
it to the middleware stack. The middleware internally calls the Rodauth
application that perfoms the authentication. This trick allows the Rodauth
application to remain reloadable.

The [Rodauth application] defines all configuration, and exposes the Rodauth
object to Rails controllers via the `env` hash. A proxy object is used to keep
the rest of our application decoupled from Rodauth.

Even though in Rodauth routes we don't yet reach our Rails router or our
controllers, we still manage to use our controllers for template rendering. We
also use an ActionMailer mailer for delivering emails.

[Rodauth]: https://github.com/jeremyevans/rodauth/
[initializer]: /config/initializers/authentication.rb
[Rodauth application]: /lib/my_app/authentication.rb
