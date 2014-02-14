Nitro Ruby
======

A simple Ruby script to enable and disable servers or services in a Netscaler v10+ appliance.  Uses the Nitro API REST client

`Usage: nitro-ruby.rb --nshost <netscaler_ip> --nsuser <netscaler_username> --nspassword <netscaler_password> --resource_type (server|service) --resource <resource_name> --action (enable|disable|list)`

Tested with Ruby 1.9.3p194