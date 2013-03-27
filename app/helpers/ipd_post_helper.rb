module IpdPostHelper

  def display_threads(threads)

    content = ''
    for thread in threads
    content << content_tag('div', 
                           link_to("#{thread.subject}",
                                   :action => 'show',
                                   :id     => thread.id) +
                           content_tag('span', 
                                       " by #{thread.user.name} &middot;" +
                                       " #{thread.created_at.format_dd_mon_yy('timestamp')}"),
                                       'style' => "margin:5px 0px; padding-left:#{thread.depth*20}px")
    end
    content
    
  end

end
