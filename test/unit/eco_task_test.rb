########################################################################
#
# Copyright 2008, by Teradyne, Inc., North Reading MA
#
# File: eco_task_test.rb
#
# This file contains the unit tests for the eco task model
#
# Revision History:
#   $Id$
#
########################################################################

require File.expand_path( "../../test_helper", __FILE__ ) 

class EcoTasksTest < ActiveSupport::TestCase

  def setup
    @task_one   = eco_tasks(:task_one)    # complete
    @task_two   = eco_tasks(:task_two)    # incomplete
    @task_three = eco_tasks(:task_three)  # incomplete
    
    @task_count = EcoTask.count
    
    @new_eco_task = EcoTask.new( :number           => 'p203322222',
                                 :pcb_revision     => 'B',
                                 :pcba_part_number => '500-501-00')
    @new_eco_task.eco_types << eco_types(:schematic)

    @emails     = ActionMailer::Base.deliveries
    @emails.clear
    
    @patrice_m = users(:patrice_m)

    @eco_document = EcoDocument.new( :name          => 'Fred.doc',
                                     :eco_task_id   => @new_eco_task.id,
                                     :data          => 'This is a spec.',
                                     :specification => true )  
                                 
    @document = EcoDocument.new( :name          => 'barney.doc',
                                 :data          => 'Rubble',
                                 :specification => 0 )
    @spec     = EcoDocument.new( :name          => 'fred.doc', 
                                 :data          => 'Flintstone',      
                                 :specification => 1 )
end

  
  ######################################################################
  def test_eco_task_state_changes
    
    test_start_time = Time.now
    eco_task_count  = EcoTask.count
    
    @new_eco_task.set_user(@patrice_m)
    @new_eco_task.save
    comment_count = @new_eco_task.eco_comments.size
    assert_equal(eco_task_count + 1, EcoTask.count)
    
    assert_nil(@new_eco_task.completed_at)
    assert_nil(@new_eco_task.closed_at)
    assert(!@new_eco_task.completed?)
    assert(!@new_eco_task.closed?)
    
    @new_eco_task.completed = true
    @new_eco_task.save
    
    assert(@new_eco_task.completed_at >= test_start_time)
    assert(@new_eco_task.completed?)
    
    assert_equal(comment_count+1, @new_eco_task.eco_comments.size)
    assert_equal('STATUS CHANGE: Task Completed', 
                 @new_eco_task.eco_comments[comment_count].comment)
    comment_count += 1
    
    @new_eco_task.closed = true
    @new_eco_task.save
    assert(@new_eco_task.closed_at >= @new_eco_task.completed_at)
    assert(@new_eco_task.closed?)
    
    assert_equal(comment_count+1, @new_eco_task.eco_comments.size)
    assert_equal('STATUS CHANGE: Task Closed', 
                 @new_eco_task.eco_comments[comment_count].comment)
    comment_count += 1
    
    @new_eco_task.closed = false
    @new_eco_task.save
    assert(!@new_eco_task.closed?)
    
    assert_equal(comment_count+1, @new_eco_task.eco_comments.size)
    assert_equal('STATUS CHANGE: Task Reopened', 
                 @new_eco_task.eco_comments[comment_count].comment)
    comment_count += 1
    
    @new_eco_task.completed = false
    @new_eco_task.save
    assert(!@new_eco_task.completed?)
    
    assert_equal(comment_count+1, @new_eco_task.eco_comments.size)
    assert_equal('STATUS CHANGE: Task Incomplete - Needs more work/input', 
                 @new_eco_task.eco_comments[comment_count].comment)
    comment_count += 1
    
  end
  
  
  ######################################################################
  def test_find_open_no_tasks
    # Remove the existing tasks in the test database.
    EcoTask.delete_all
    
    assert_equal(0, EcoTask.find_open.size)
  end
  
  
  ######################################################################
  def test_find_closed_none_closed
    # Remove task 1, it is closed
    @task_one.destroy
    assert_equal(0, EcoTask.find_closed(Time.at(0), Time.now).size)
  end
  
  
  ######################################################################
  def test_find_open_no_active_tasks
    EcoTask.delete(@task_two.id)
    EcoTask.delete(@task_three.id)
    
    assert_equal(0, EcoTask.find_open.size)
  end

  
  ######################################################################
  def test_find_open_one_active_task
    EcoTask.delete(@task_two.id)

    open_tasks = EcoTask.find_open
    assert_equal(1,                  open_tasks.size)
    assert_equal(@task_three.number, open_tasks[0].number)
  end

  
  ######################################################################
  def test_find_closed_one_closed
    # Initially, only task one is closed
    assert_equal(1, EcoTask.find_closed(Time.at(0).to_date, Time.now+1.year).size)
  end

  
  ######################################################################
  def test_find_open_multiple_active_tasks
    open_tasks = EcoTask.find_open
    assert_equal(2,           open_tasks.size)
    assert_equal(@task_two,   open_tasks[0])
    assert_equal(@task_three, open_tasks[1])
  end

  
  ######################################################################
  def test_find_closed_multiple_closed
    # Initially, only task one is closed
    @new_eco_task.closed    = true
    @new_eco_task.closed_at = Time.now
    @new_eco_task.save
    assert_equal(2, EcoTask.find_closed(Time.at(0).to_date, Time.now).size)
  end
  
  
  ######################################################################
  def test_create_valid

    @new_eco_task.save
    assert_equal(@task_count + 1, EcoTask.count)
    assert_equal(0,               @new_eco_task.errors.size)
    
    new_eco_task = EcoTask.new( :number           => 'p203322223',
                                :pcb_revision     => 'J',
                                :pcba_part_number => '500-501-00')
    new_eco_task.eco_types << eco_types(:schematic)
    new_eco_task.save
    assert_equal(@task_count + 2, EcoTask.count)
    assert_equal(0,               new_eco_task.errors.size)
    
    new_eco_task = EcoTask.new( :number           => 'p203322224',
                                :pcb_revision     => 'V',
                                :pcba_part_number => '543-343-33')
    new_eco_task.eco_types << eco_types(:schematic)
    new_eco_task.save
    assert_equal(@task_count + 3, EcoTask.count)
    assert_equal(0,               new_eco_task.errors.size)
    assert_equal(0,               @emails.size)
    
  end

  
  ######################################################################
  def test_update_valid
    @new_eco_task.save
    assert_equal(@task_count + 1, EcoTask.count)
    assert_equal(0,               @new_eco_task.errors.size)
    
    # Verify that the ECO tasks can be updated
    eco_type_count = @new_eco_task.eco_types.size
    @new_eco_task.eco_types << eco_types(:fabrication_drawing)
    @new_eco_task.save

    assert_equal(eco_type_count + 1, @new_eco_task.eco_types.size)
    assert(@new_eco_task.eco_types.detect{ |eco_type| eco_type == eco_types(:fabrication_drawing) })
    assert(@new_eco_task.eco_types.detect{ |eco_type| eco_type == eco_types(:schematic) })
    assert_equal(0, @new_eco_task.errors.size)
    
    @new_eco_task.number = 'p714'
    @new_eco_task.save
    
    assert_equal(0, @new_eco_task.errors.size)
    @new_eco_task.reload
    assert_equal('p714', @new_eco_task.number)
    
    @new_eco_task.number = ''
    @new_eco_task.save
    
    assert(@new_eco_task.errors.size == 1)
    assert_equal('The ECO Number field can not be blank',
                 @new_eco_task.errors[:number][0])
    
    @new_eco_task.number       = 'p714'
    @new_eco_task.pcb_revision = 'T'
    @new_eco_task.save

    assert_equal(0, @new_eco_task.errors.size)
    @new_eco_task.reload
    assert_equal('p714', @new_eco_task.number)
    assert_equal('T',    @new_eco_task.pcb_revision)
    
    @new_eco_task.pcb_revision = ''
    @new_eco_task.save
    
    assert(@new_eco_task.errors.size == 1)
    assert_equal('You must provide a PCB Revision.',
                 @new_eco_task.errors[:pcb_revision][0])
    
    @new_eco_task.pcb_revision     = 'T'
    @new_eco_task.pcba_part_number = '987-765-33'
    @new_eco_task.save

    assert_equal(0, @new_eco_task.errors.size)
    @new_eco_task.reload
    assert_equal('p714',       @new_eco_task.number)
    assert_equal('T',          @new_eco_task.pcb_revision)
    assert_equal('987-765-33',@new_eco_task.pcba_part_number)
    assert_equal(0,            @emails.size)
    
    @new_eco_task.pcba_part_number = ''
    @new_eco_task.save
    
    assert(@new_eco_task.errors.size == 1)
    assert_equal('You must provide a PCBA Part Number.',
                 @new_eco_task.errors[:pcba_part_number][0])
    
    
  end

  
  ######################################################################
  def test_create_no_pcb_revision_pcba_pn
    @new_eco_task.pcb_revision     = ''
    @new_eco_task.pcba_part_number = ''
    @new_eco_task.save
    assert_equal(@task_count, EcoTask.count)
    assert_equal(2,           @new_eco_task.errors.size)
    assert_equal('You must provide a PCB Revision.',
                 @new_eco_task.errors[:pcb_revision][0])
    assert_equal('You must provide a PCBA Part Number.',
                 @new_eco_task.errors[:pcba_part_number][0])
    assert_equal(0, @emails.size)
    
  end
  
  
  ######################################################################
  def test_update_no_pcb_revision_pcba_pn
    eco_task_count = EcoTask.count
    @new_eco_task.save
    assert_equal(eco_task_count + 1, EcoTask.count)
    
    @new_eco_task.pcb_revision  = ''
    @new_eco_task.pcba_part_number = ''
    @new_eco_task.save
    
    assert_equal(2, @new_eco_task.errors.size)
    assert_equal('You must provide a PCB Revision.',
                 @new_eco_task.errors[:pcb_revision][0])
    assert_equal('You must provide a PCBA Part Number.',
                 @new_eco_task.errors[:pcba_part_number][0])
    assert_equal(0, @emails.size)
  end
  
  
  ######################################################################
  def test_create_no_eco_number
    @new_eco_task.number = ''
    @new_eco_task.save
    assert_equal(@task_count, EcoTask.count)
    assert_equal("The ECO Number field can not be blank",
      @new_eco_task.errors[:number][0])
    assert_equal(0, @emails.size)
    
 end

  
  ######################################################################
  def test_update_no_eco_number
    eco_task_count = EcoTask.count
    @new_eco_task.save
    assert_equal(eco_task_count + 1, EcoTask.count)
    
    @new_eco_task.number = ''
    @new_eco_task.save
    assert_equal("The ECO Number field can not be blank",
      @new_eco_task.errors[:number][0])
    assert_equal(0, @emails.size)
      end
  
  
  ######################################################################
  def test_create_no_eco_types
    @new_eco_task.eco_types.pop
    @new_eco_task.save
    assert_equal(@task_count, EcoTask.count)
    assert_equal("You must select at least one ECO Type.",@new_eco_task.errors[:eco_types][0])
    assert_equal(0, @emails.size)
  end

  
  ######################################################################
  def test_update_no_eco_types
    eco_task_count = EcoTask.count
    @new_eco_task.save
    assert_equal(eco_task_count + 1, EcoTask.count)
    
    @new_eco_task.eco_types.pop
    @new_eco_task.save
    assert_equal("You must select at least one ECO Type.",
      @new_eco_task.errors[:eco_types][0])
    assert_equal(0, @emails.size)
  end
  

  ######################################################################
  def test_specification_identified
    
    eco_task_count = EcoTask.count
    @new_eco_task.save
    assert_equal(eco_task_count + 1, EcoTask.count)
    
    assert(!@new_eco_task.specification_identified?)
    
    @new_eco_task.document_link = '        '
    assert(!@new_eco_task.specification_identified?)
    
    @new_eco_task.attach_document(@document, @patrice_m)
    @new_eco_task.reload
    assert(!@new_eco_task.specification_identified?)
    assert_equal(0, @emails.size)
 
    @new_eco_task.attach_document(@spec, @patrice_m, true)
    @new_eco_task.reload

    assert(@new_eco_task.specification_identified?)
    assert_equal(0, @emails.size)
    
    @new_eco_task.document_link = '/hwnet/dtg_devel/'
    @new_eco_task.save
    @new_eco_task.reload
    assert(@new_eco_task.specification_identified?)
    
    @new_eco_task.eco_documents.pop
    @new_eco_task.eco_documents.pop
    assert_equal(0, @new_eco_task.eco_documents.size)
    
    @new_eco_task.document_link = ' '
    assert(!@new_eco_task.specification_identified?)
    
  end
    
  
  ######################################################################
  def test_specification_methods
    
    eco_task_count = EcoTask.count
    @new_eco_task.save
    assert_equal(eco_task_count + 1, EcoTask.count)
    
    assert_equal(0, @new_eco_task.attachments.size)
    assert(!@new_eco_task.attachments?)
    assert(!@new_eco_task.specification_attached?)
    assert_nil(@new_eco_task.specification)
   
    @new_eco_task.attach_document(@document, @patrice_m)
    @new_eco_task.reload
    assert_equal(0, @emails.size)
    
    assert_equal(1, @new_eco_task.attachments.size)
    assert(@new_eco_task.attachments?)
    assert(!@new_eco_task.specification_attached?)
    assert_nil(@new_eco_task.specification)
    
    @new_eco_task.attach_document(@spec, @patrice_m, true)
    @new_eco_task.reload
    
    assert_equal(1, @new_eco_task.attachments.size)
    assert_equal(@spec, @new_eco_task.specification)
    assert(@new_eco_task.attachments?)
    assert(@new_eco_task.specification_attached?)
    assert_equal(0, @emails.size)
    
    assert(@new_eco_task.destroy_specification)
    assert_equal(1, @new_eco_task.attachments.size)
    assert_nil(@new_eco_task.specification)
    assert(@new_eco_task.attachments?)
    assert(!@new_eco_task.specification_attached?)
    
    assert(!@new_eco_task.destroy_specification)
    
    EcoDocument.destroy_all
    @new_eco_task.reload
    assert(!@new_eco_task.attachments?)

    
    
  end
  
  
  ######################################################################
  def test_add_comments
    
    eco_task_count = EcoTask.count
    @new_eco_task.save
    assert_equal(eco_task_count + 1, EcoTask.count)
    
    assert_equal(0, @new_eco_task.eco_comments.size)
    
    
    eco_comment = EcoComment.new( :comment => '')
    @new_eco_task.add_comment(eco_comment, @patrice_m)
    @new_eco_task.reload
    assert_equal(0, @new_eco_task.eco_comments.size)
    
    eco_comment.comment = '       '
    @new_eco_task.add_comment(eco_comment, @patrice_m)
    @new_eco_task.reload
    assert_equal(0, @new_eco_task.eco_comments.size)
    
    eco_comment.comment = 'This is a test.'
    @new_eco_task.add_comment(eco_comment, @patrice_m)
    @new_eco_task.reload
    assert_equal(1, @new_eco_task.eco_comments.size)
    comment = @new_eco_task.eco_comments.shift
    assert_equal(@patrice_m, comment.user)
    
  end
  
  
  ######################################################################
  def test_eco_type_methods

    eco_task_count = EcoTask.count
    @new_eco_task.save
    assert_equal(eco_task_count + 1, EcoTask.count)
   
    assert(@new_eco_task.schematic?)
    assert(!@new_eco_task.assembly_drawing?)
    assert(!@new_eco_task.fabrication_drawing?)
    
    @new_eco_task.eco_types << eco_types(:assembly_drawing)
    assert(@new_eco_task.schematic?)
    assert(@new_eco_task.assembly_drawing?)
    assert(!@new_eco_task.fabrication_drawing?)

    @new_eco_task.eco_types << eco_types(:fabrication_drawing)
    assert(@new_eco_task.schematic?)
    assert(@new_eco_task.assembly_drawing?)
    assert(@new_eco_task.fabrication_drawing?)
    
    @new_eco_task.eco_types.shift
    assert(!@new_eco_task.schematic?)
    assert(@new_eco_task.assembly_drawing?)
    assert(@new_eco_task.fabrication_drawing?)
    
    @new_eco_task.eco_types.shift
    assert(!@new_eco_task.schematic?)
    assert(!@new_eco_task.assembly_drawing?)
    assert(@new_eco_task.fabrication_drawing?)
    
    @new_eco_task.eco_types.shift
    assert(!@new_eco_task.schematic?)
    assert(!@new_eco_task.assembly_drawing?)
    assert(!@new_eco_task.fabrication_drawing?)
    
  end
  
  
  ######################################################################
  def test_create_no_specification
    @new_eco_task.save
    assert(!@new_eco_task.specification_identified?)
    assert_nil(@new_eco_task.started_at)
  end
  
  
  ######################################################################
  def test_update_no_specification
    @new_eco_task.save
    assert(!@new_eco_task.specification_identified?)
    assert_nil(@new_eco_task.started_at)
    
    @new_eco_task.number = 'p32323'
    @new_eco_task.save
    assert(!@new_eco_task.specification_identified?)
    assert_nil(@new_eco_task.started_at)
  end
  
  
  ######################################################################
  def test_create_specification_attached
    
    test_start_time             = Time.now    

    @new_eco_task.save
    @new_eco_task.attach_document(@eco_document, @patrice_m, true)
    @new_eco_task.reload
    
    assert(@new_eco_task.specification_identified?)
    assert_not_nil(@new_eco_task.started_at)
    assert_equal((@new_eco_task.started_at <=> test_start_time), -1)
    assert_equal(0, @emails.size)
    
  end
  
  
  ######################################################################
  def test_create_specification_attached_link_loaded
    
    test_start_time             = Time.now
    @new_eco_task.document_link = '/hwnet/dtg_devel'

    @new_eco_task.save
    @new_eco_task.attach_document(@eco_document, @patrice_m, true)
    @new_eco_task.reload
    
    assert(@new_eco_task.specification_identified?)
    assert_not_nil(@new_eco_task.started_at)
    assert_equal((@new_eco_task.started_at <=> test_start_time), -1)
    assert_equal(0, @emails.size)
    
  end
  
  
  ######################################################################
  def test_create_link_loaded
    test_start_time             = Time.now
    @new_eco_task.document_link = '/hwnet/dtg_devel'
    @new_eco_task.save
    @new_eco_task.reload
    
    assert(@new_eco_task.specification_identified?)
    assert_not_nil(@new_eco_task.started_at)
    assert_equal((@new_eco_task.started_at <=> test_start_time), -1)
    assert_equal(0, @emails.size)
  end
  
  
  
  ######################################################################
  def test_specification_attached_link_loaded_remove_link
    
    test_start_time             = Time.now
    @new_eco_task.document_link = '/hwnet/dtg_devel'

    @new_eco_task.save
    @new_eco_task.attach_document(@eco_document, @patrice_m, true)
    @new_eco_task.reload
    
    assert(@new_eco_task.specification_identified?)
    assert_not_nil(@new_eco_task.started_at)
    assert_equal((@new_eco_task.started_at <=> test_start_time), -1)
    specification_time = @new_eco_task.started_at
    
    @new_eco_task.document_link = ''
    @new_eco_task.save
    
    assert(@new_eco_task.specification_identified?)
    assert_not_nil(@new_eco_task.started_at)
    assert_equal((@new_eco_task.started_at <=> specification_time), 0)
    assert_equal(0, @emails.size)

  end
  
  
  ######################################################################
  def test_specification_attached_link_loaded_remove_attachment
    
    test_start_time             = Time.now
    @new_eco_task.document_link = '/hwnet/dtg_devel'

    @new_eco_task.save
    @new_eco_task.attach_document(@eco_document, @patrice_m, true)
    @new_eco_task.reload
    
    assert(@new_eco_task.specification_identified?)
    assert_not_nil(@new_eco_task.started_at)
    assert_equal((@new_eco_task.started_at <=> test_start_time), -1)
    specification_time = @new_eco_task.started_at
    
    @eco_document.destroy
    @new_eco_task.reload
    
    assert(@new_eco_task.specification_identified?)
    assert_not_nil(@new_eco_task.started_at)
    assert_equal((@new_eco_task.started_at <=> specification_time), 0)
    assert_equal(0, @emails.size)

  end
  
  
  ######################################################################
  def test_specification_attached_link_loaded_remove_all_specs
    
    test_start_time             = Time.now
    @new_eco_task.document_link = '/hwnet/dtg_devel'

    @new_eco_task.save
    @new_eco_task.attach_document(@eco_document, @patrice_m, true)
    @new_eco_task.reload
    
    assert(@new_eco_task.specification_identified?)
    assert_not_nil(@new_eco_task.started_at)
    assert_equal((@new_eco_task.started_at <=> test_start_time), -1)
    specification_time = @new_eco_task.started_at
    
    @eco_document.destroy
    @new_eco_task.document_link = ''
    @new_eco_task.save
    @new_eco_task.reload
    
    assert(!@new_eco_task.specification_identified?)
    assert_equal(0, @emails.size)

  end
  
  
  ######################################################################
  def test_eco_uniqueness_validation_of_eco_number
    
    eco_task_count = EcoTask.count
    @new_eco_task.save
    assert_equal(eco_task_count+1, EcoTask.count)
    
    @dup_eco_number = EcoTask.new( :number           => 'p203322222',
                                   :pcb_revision     => 'B',
                                   :pcba_part_number => '500-501-01')
    @dup_eco_number.eco_types << eco_types(:schematic)
    @dup_eco_number.save

    assert_equal(0,           @dup_eco_number.errors.size)
    
    assert_nil(@dup_eco_number.errors[:number][0])
    assert_equal(eco_task_count+2, EcoTask.count)

  end
  
  
  ######################################################################
  def test_set_user
    assert_nil(@new_eco_task.get_user)
    @new_eco_task.set_user(@patrice_m)
    assert_equal(@patrice_m, @new_eco_task.get_user)
  end
  
  
  ######################################################################
  def test_state_incomplete
    assert_equal('Incomplete', @new_eco_task.state)
  end
  
  
  ######################################################################
  def test_state_completed
    @new_eco_task.completed = true
    assert_equal('Complete', @new_eco_task.state)
  end
  
  
  ######################################################################
  def test_state_closed
    @new_eco_task.completed = true
    @new_eco_task.closed    = true
    assert_equal('Closed', @new_eco_task.state)
  end
  
  
  ######################################################################
  def test_update_cc_list
    
    eco_task_count = EcoTask.count
    @new_eco_task.save
    assert_equal(eco_task_count+1, EcoTask.count)
    
    assert_equal([], @new_eco_task.users)
    user_list = [@patrice_m, users(:cathy_m)]
    @new_eco_task.add_users_to_cc_list(user_list.map(&:id))
    @new_eco_task.reload
    
    assert_equal(2, @new_eco_task.users.size)
    assert_equal(user_list, @new_eco_task.users)
    
  end
  
  
  ######################################################################
  def test_users_eligible_for_cc_list
    
    all_active_users = User.find(:all, :conditions => 'active=1')
    diff             = all_active_users - @new_eco_task.users_eligible_for_cc_list
    
    # Remove the following users that are should not be returned by the method
    # They are included on the mailing list automatically.
    not_eligible = [ users(:cathy_m),  users(:jim_l),  users(:siva_e),
                     users(:jan_k),    users(:bala_g), users(:mathi_n),
                     users(:patrice_m) ]
    diff -= not_eligible
    
    assert_equal([], diff)
    
    @new_eco_task.add_users_to_cc_list([users(:pat_a).id])
    diff             = all_active_users - @new_eco_task.users_eligible_for_cc_list
    diff -= not_eligible + [users(:pat_a)]
    
    assert_equal([], diff)
    
  end
  
  
  ######################################################################
  def test_for_admin_updates
    
    eco_task_count = EcoTask.count
    @new_eco_task.save
    assert_equal(eco_task_count+1, EcoTask.count)
    
    old_copy = EcoTask.find(@new_eco_task.id)
    assert(!old_copy.check_for_admin_update(@new_eco_task))
    
    @new_eco_task.number = '987654321'
    assert(old_copy.check_for_admin_update(@new_eco_task))
    @new_eco_task.number = old_copy.number
    assert(!old_copy.check_for_admin_update(@new_eco_task))
    
    @new_eco_task.pcb_revision = 'Q'
    assert(old_copy.check_for_admin_update(@new_eco_task))
    @new_eco_task.pcb_revision = old_copy.pcb_revision
    assert(!old_copy.check_for_admin_update(@new_eco_task))
    
    @new_eco_task.pcba_part_number = '999-888-00'
    assert(old_copy.check_for_admin_update(@new_eco_task))
    @new_eco_task.pcba_part_number = old_copy.pcba_part_number
    assert(!old_copy.check_for_admin_update(@new_eco_task))
    
    @new_eco_task.document_link = '/u/dtg/this_is_test'
    assert(old_copy.check_for_admin_update(@new_eco_task))
    @new_eco_task.document_link = old_copy.document_link
    assert(!old_copy.check_for_admin_update(@new_eco_task))
    
    @new_eco_task.completed = true
    assert(old_copy.check_for_admin_update(@new_eco_task))
    @new_eco_task.completed = false
    assert(!old_copy.check_for_admin_update(@new_eco_task))
    
    @new_eco_task.closed = true
    assert(old_copy.check_for_admin_update(@new_eco_task))
    @new_eco_task.closed = false
    assert(!old_copy.check_for_admin_update(@new_eco_task))

    @new_eco_task.eco_types << eco_types(:fabrication_drawing)
    assert(old_copy.check_for_admin_update(@new_eco_task))
    @new_eco_task.eco_types = old_copy.eco_types
    assert(!old_copy.check_for_admin_update(@new_eco_task))
    
    @new_eco_task.number           = '987654321'
    @new_eco_task.pcb_revision     = 'Q'
    @new_eco_task.pcba_part_number = '999-888-00'
    @new_eco_task.document_link    = '/u/dtg/this_is_test'
    @new_eco_task.completed        = true
    @new_eco_task.closed           = true
    @new_eco_task.eco_types << eco_types(:fabrication_drawing)
    assert(old_copy.check_for_admin_update(@new_eco_task))
    @new_eco_task.number           = old_copy.number
    @new_eco_task.pcb_revision     = old_copy.pcb_revision
    @new_eco_task.pcba_part_number = old_copy.pcba_part_number
    @new_eco_task.document_link    = old_copy.document_link
    @new_eco_task.completed        = false
    @new_eco_task.closed           = false
    @new_eco_task.eco_types        = old_copy.eco_types
    assert(!old_copy.check_for_admin_update(@new_eco_task))

  end
  
  
  def dump_eco_tasks(msg)
    puts
    puts '#### ' + msg + ' ####'
    etl = EcoTask.find(:all)
    etl.each do |et|
      puts 'ID: ' + et.id.to_s +  '  Number: ' + et.number + '  Closed: ' + et.closed.to_s
    end
  end

  
end
