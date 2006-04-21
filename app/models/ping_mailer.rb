class PingMailer < ActionMailer::Base

  def summary(ping_list)
    @subject    = 'Summary of reviewers who have not approved/waived design reviews'
    ping_list.to_a
    @body       = {:ping_list => ping_list}
    
    recipients = []
    pcb_input_gate_list = Role.find_by_name('PCB Input Gate')
    for user in pcb_input_gate_list.users
      recipients << user.email if user.active?
    end
    manager_list = Role.find_by_name('Manager')
    for user in manager_list.users
      recipients << user.email if user.active?
    end
    
    @recipients = recipients.uniq
    @from       = Pcbtr::SENDER
    @sent_on    = Time.now
    @headers    = {}
  end

  def ping(review_result_list)
    @subject    = 'Your unresolved Design Review(s)'
    @recipients = review_result_list[:reviewer].email
    @from       = Pcbtr::SENDER
    @sent_on    = Time.now
    @headers    = {}

    @body[:review_list] = review_result_list[:review_list]
  end
end
