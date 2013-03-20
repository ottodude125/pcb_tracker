module MailerMethods
  
  ######################################################################
  #
  # reviewer_list
  #
  # Description:
  # Given a design review this method will return a list of the
  # reviewer emails
  #
  # Parameters:
  #   design_review - the design review to get the reviewers for.
  #
  ######################################################################
  #
  def self.reviewer_list(design_review)

    reviewers = []
    design_review_results = 
      DesignReviewResult.find_all_by_design_review_id(design_review.id)

    design_review_results.each do |dr_result|
      reviewer = User.find(dr_result.reviewer_id)
      reviewers << reviewer.email if reviewer.active?
    end

    return reviewers.uniq
    
  end


  ######################################################################
  #
  # copy_to
  #
  # Description:
  # Given a design review this method will return a list of the
  # people who should be CC'ed on all mails
  #
  # Parameters:
  #   design_review - the design review to get the CC list for.
  #
  ######################################################################
  #
  def self.copy_to(design_review)

    cc_list = [design_review.designer.email]
    cc_list << design_review.design.designer.email if design_review.design.designer_id > 0

    design_review.design.board.users.each do |cc|
      cc_list << cc.email if cc.active?
    end

    cc_list += Role.add_role_members(['Manager', 'PCB Input Gate'])
    return cc_list.uniq

  end


  ######################################################################
  #
  # copy_to_on_milestone
  #
  # Description:
  # Given a board this method will return a list of the
  # people who should be CC'ed on all milestone mails
  #
  # Parameters:
  #   board - the board to get the milestone CC list for.
  #
  ######################################################################
  #
  def self.copy_to_on_milestone(board)
    add_board_reviewer(board,
                       ['Program Manager',
                        'Hardware Engineering Manager'])
  end
  
  
  ######################################################################
  #
  # add_board_reviewer
  #
  # Description:
  # Given a board and a list of roles this function will load the
  # CC list with users associated with the role for that board.
  #
  # Parameters:
  #   board - the board record.
  #   roles - a list of roles.  The associated user's email will be
  #           added to the CC list.
  #
  ######################################################################
  #
  def self.add_board_reviewer(board, roles)
  
    cc_list   = []
    role_list = Role.find(:all)

    roles.each do |role|

      reviewer_role  = role_list.detect { |r| r.name == role }
      board_reviewer = board.board_reviewers.detect { |br| br.role_id == reviewer_role.id }

      if board_reviewer && board_reviewer.reviewer_id?
        cc_list << User.find(board_reviewer.reviewer_id).email
      end
    
    end
    
    return cc_list
    
  end
  
  
  ######################################################################
  #
  # subject_prefix
  #
  # Description:
  # Provides a common prefix for subjects
  #
  # Parameters:
  #   None
  #
  ######################################################################
  #
  def self.subject_prefix(design)
    design.board.platform.name + '/' +
    design.board.project.name  + '/' +
    design.board.description   + '(' +
    design.directory_name      +  '): '
  end
end