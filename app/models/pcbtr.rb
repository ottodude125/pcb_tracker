class Pcbtr < ActiveRecord::Base

MESSAGES = {
  :admin_only => 'Administrators only!  Check your role.'
}

PCBTR_BASE_URL = 'http://linuxolten.icd.teradyne.com/tracker/'
SENDER         = 'PCB_Tracker'
EAVESDROP      = 'paul_altimonte@notes.teradyne.com'


end
