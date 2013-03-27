# $Id$ 
# Authenticate using LDAP

require 'net/ldap'

def ldap_authenticated?(login,password)
  return false if password.blank?
  
  if ! login.match('^TER')
    login = "TER\\"+login
  end

  begin
    ldap = Net::LDAP.new
    ldap.host = 'ter.teradyne.com'
    ldap.port = 389
    ldap.auth login, password
    if ldap.bind
      return true
    else
      return false
    end
  rescue
    return false
  end
end
