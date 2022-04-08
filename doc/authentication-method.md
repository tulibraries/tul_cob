Authentication with the IDP
===
This document provides a summary of the technologies being used for authenticating against the Temple U. Identity Provider (IDP).

Firstly, I would like to state that there are currently two concurrent ways that we use to authenticate users in different environments. The first way (Shibboleth SAML) is through an Apache Shibboleth plugin for a Shibboleth process/service that runs on each of the following environments: librarysearch.qa.tul-infra.page (qa), librarybeta.temple.edu (stage) and librarysearch.temple.edu (prod).

The other competing way of authenticating (Ruby SAML) which does not require a separate process outside of the running app, is set up to work on the librarysearch.k8s.temple.edu (qa-k8) and localhost (dev/local) environments.

The reason we currently have two ways of authenticating users is that we are in the process of migrating authentication to use Ruby SAML only, but we have not completely transitioned over.

Both authentication processes use SAML, and both require that a Service Provider (SP) account be set up via the Temple Office of Identity and Access Management. This is partly the reason the transition has taken longer than expected. Because every change requires coordination with another department.


## Ruby SAML:
The Ruby SAML setup is by far the simpler of the two authentication methods. The reason is that it only requires an understanding of the Ruby application. In contrast, the Shibboleth SAML method requires us to manage and understand Apache and Shibboleth-SP as well as the Ruby application.

This method uses multiple Ruby gems that work in concert to deliver the feature. The Ruby gems are devise, omniauth-saml, and ruby-saml. But, as users, we only need to have a superficial understanding of how all this is set up.

Configuration of the Ruby-SAML method:

The configuration for this method is in config/devise.yml

### Controller:
When the IDP returns with the user metadata after a successful authentication is completed, the user is returned to the Users::OmniauthCallbackController.saml action.

This is where we can officially sign in the user into the application as well as take any user session specific actions.

### Model:
Devise and Omniauth specific configuration are added to the User model. The User.from_omniauth method is where the authentication metadata from the IDP is mapped to the application User instance.

### Metadata:
Access to the SP metadata for the Ruby SAML authentication method is via the /user/auth/saml/metadata path. The XML file defined at this endpoint is what is required to set up an SP identity in the IDP. If changes happen to this metadata the record on the IDP must be updated. And this update needs to happen via the Office of Identity Access since they manage the IDP server.

## Shibboleth SAML:
The Shibboleth method requires both an understanding of application-level code as well as outside processes. Thus, compared to Ruby-SAML it is by far more complicated. Fortunately, some of this complication is managed via an ansible role that takes care of the configuring and running the SP dependencies.

### Shibd:
Shibd is a program that runs on a server and provides the role of the SP. It is a separate process from the Ruby application or from the server application (Apache). But it is configured to work with both applications to deliver the authentication feature.

This application is configured via an XML file which in our case is managed via an Ansible role at https://github.com/tulibraries/ansible-role-shibboleth-sp/blob/main/templates/shibboleth2.xml.j2.

### Apache:
Apache is then configured to work with this process. The Apache level configurations are also managed by the same role: https://github.com/tulibraries/ansible-role-shibboleth-sp/blob/main/templates/shib.conf.j2.

Changes to either of these files require a restart of both httpd (Apache) and the shibd (Shibboleth SP) services. This is also managed via the Ansible role: https://github.com/tulibraries/ansible-role-shibboleth-sp/blob/main/tasks/main.yml#L28-L29

## Ruby Application Level:

### Configuration:
The configuration file for this method is config/devise.yml (It’s the same file use as for Ruby-SAML).

### Controller:
When the IDP returns with the user metadata after a successful authentication is completed, the user is returned to the Users::OmniauthCallbackController.shibboleth action.

This is where we can officially sign in the user into the application as well as take any user session specific actions.

### Model:
Devise and Omniauth specific configuration are added to the User model. The User.from_omniauth method is where the authentication metadata from the IDP is mapped to the application User instance.

### Metadata:
Access to the SP metadata for the Ruby SAML authentication method is via the /Shibboleth.sso/Metadata. The XML file defined at this endpoint is what is required to set up an SP identity in the IDP. If changes happen to this metadata the record on the IDP must be updated. And this update needs to happen via the Office of Identity Access since they manage the IDP server.

##Caveats:
Newer version of the shibd program require interaction to happen via HTTPS.  This requires a change to the SP metadata which needs to be coordinated with the Office of Identity Access. Also this means that any path that is load balance needs to be encrypted.
