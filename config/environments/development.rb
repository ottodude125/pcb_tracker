require 'socket'

PcbTracker::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # disable rake-cache error logging
  #config.action_dispatch.rack_cache[:verbose] = false
  
  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_deliveries = true
  
  sock = Socket.gethostname
  if !sock.index("katonj-mac").nil?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.default_url_options = { :to => "jonathan.katon@teradyne.com"}
    config.action_mailer.smtp_settings = {
      address:              'smtp.gmail.com',
      port:                 587,
      domain:               'gmail.com',
      user_name:            'ottodude125@gmail.com',
      password:             'Gr0phic0l',
      authentication:       'plain',
      enable_starttls_auto: true  }  
  end
  
  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true
  
  # Exception e-mail notifier - here for testing, needed in production
  #config.middleware.use ExceptionNotifier,
  #:email_prefix => "[Exception] ",
  #:sender_address => %{DEVEL_PCB_Tracker <dtg_noreply@lists.teradyne.com>},
  #:exception_recipients => %w{dtg_ror_devel@lists.teradyne.com}

  #Allow BetterErrors to work on client other than "localhost"
  #You can find your apparent IP by hitting the old error page's "Show env dump" and looking at "REMOTE_ADDR".
  #allow_ip! is actually backed by a Set, so you can add more than one IP address or subnet.
  BetterErrors::Middleware.allow_ip! "131.101.160.151"
  BetterErrors::Middleware.allow_ip! '131.101.103.241' #mimir1
  BetterErrors::Middleware.allow_ip! '131.101.60.26' #???
  BetterErrors::Middleware.allow_ip! '132.223.6.104' #mac pro
  BetterErrors::Middleware.allow_ip! '132.223.5.51' #mac pro

end
