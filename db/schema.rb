# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110426194243) do

  create_table "audit_comments", :force => true do |t|
    t.integer  "design_check_id", :limit => 12, :default => 0, :null => false
    t.integer  "user_id",         :limit => 12, :default => 0, :null => false
    t.datetime "created_on"
    t.text     "comment",                                      :null => false
  end

  add_index "audit_comments", ["design_check_id"], :name => "design_check_id"

  create_table "audit_teammates", :force => true do |t|
    t.integer "audit_id",   :limit => 12, :default => 0, :null => false
    t.integer "section_id", :limit => 12, :default => 0, :null => false
    t.integer "user_id",    :limit => 12, :default => 0, :null => false
    t.integer "self",       :limit => 3,  :default => 0, :null => false
  end

  add_index "audit_teammates", ["user_id"], :name => "user_id"
  add_index "audit_teammates", ["audit_id"], :name => "audit_id"

  create_table "audits", :force => true do |t|
    t.integer "design_id",                 :limit => 12, :default => 0, :null => false
    t.integer "checklist_id",              :limit => 12, :default => 0, :null => false
    t.integer "skip",                      :limit => 3,  :default => 0, :null => false
    t.integer "designer_complete",         :limit => 3,  :default => 0, :null => false
    t.integer "auditor_complete",          :limit => 3,  :default => 0, :null => false
    t.integer "designer_completed_checks", :limit => 3,  :default => 0, :null => false
    t.integer "auditor_completed_checks",  :limit => 3,  :default => 0, :null => false
    t.integer "lock_version",              :limit => 12, :default => 0, :null => false
  end

  create_table "board_design_entries", :force => true do |t|
    t.integer  "part_number_id",                 :limit => 12,  :default => 0,            :null => false
    t.integer  "location_id",                    :limit => 3,   :default => 0,            :null => false
    t.integer  "division_id",                    :limit => 3,   :default => 0,            :null => false
    t.integer  "platform_id",                    :limit => 3,   :default => 0,            :null => false
    t.integer  "project_id",                     :limit => 3,   :default => 0,            :null => false
    t.string   "description",                    :limit => 80,  :default => "",           :null => false
    t.string   "pre_production_release_number",  :limit => 32,  :default => "",           :null => false
    t.integer  "product_type_id",                :limit => 3,   :default => 0,            :null => false
    t.string   "review_doc_location",            :limit => 128, :default => "",           :null => false
    t.integer  "prefix_id",                      :limit => 3,   :default => 0,            :null => false
    t.string   "number",                         :limit => 3,   :default => "",           :null => false
    t.integer  "revision_id",                    :limit => 3,   :default => 0,            :null => false
    t.integer  "numeric_revision",               :limit => 3,   :default => 0,            :null => false
    t.string   "eco_number",                     :limit => 7,   :default => "",           :null => false
    t.string   "entry_type",                     :limit => 16,  :default => "",           :null => false
    t.integer  "user_id",                        :limit => 12,  :default => 0,            :null => false
    t.string   "state",                          :limit => 16,  :default => "originated", :null => false
    t.datetime "submitted_on"
    t.integer  "make_from",                      :limit => 3,   :default => 0,            :null => false
    t.string   "original_pcb_number",            :limit => 16,  :default => "",           :null => false
    t.string   "outline_drawing_number",         :limit => 32,  :default => "",           :null => false
    t.integer  "hipot_testing_required",         :limit => 3,   :default => 0,            :null => false
    t.integer  "lead_free_devices",              :limit => 3,   :default => 0,            :null => false
    t.text     "lead_free_device_names",                                                  :null => false
    t.integer  "design_directory_id",            :limit => 3,   :default => 0
    t.integer  "incoming_directory_id",          :limit => 3,   :default => 0
    t.integer  "differential_pairs",             :limit => 3,   :default => 0,            :null => false
    t.integer  "controlled_impedance",           :limit => 3,   :default => 0,            :null => false
    t.integer  "scheduled_nets",                 :limit => 3,   :default => 0,            :null => false
    t.integer  "propagation_delay",              :limit => 3,   :default => 0,            :null => false
    t.integer  "matched_propagation_delay",      :limit => 3,   :default => 0,            :null => false
    t.integer  "outline_drawing_document_id",    :limit => 12,  :default => 0,            :null => false
    t.integer  "pcb_attribute_form_document_id", :limit => 12,  :default => 0,            :null => false
    t.integer  "teradyne_stackup_document_id",   :limit => 12,  :default => 0,            :null => false
    t.text     "originator_comments",                                                     :null => false
    t.text     "input_gate_comments",                                                     :null => false
    t.datetime "requested_start_date"
    t.datetime "requested_completion_date"
    t.integer  "details_complete",               :limit => 3,   :default => 0,            :null => false
    t.integer  "constraints_complete",           :limit => 3,   :default => 0,            :null => false
    t.integer  "management_team_complete",       :limit => 3,   :default => 0,            :null => false
    t.integer  "review_team_complete",           :limit => 3,   :default => 0,            :null => false
    t.integer  "attachments_complete",           :limit => 3,   :default => 0,            :null => false
    t.integer  "comments_complete",              :limit => 3,   :default => 0,            :null => false
    t.integer  "design_id",                      :limit => 12,  :default => 0,            :null => false
    t.boolean  "rohs"
    t.boolean  "thieving"
    t.boolean  "no_copper"
  end

  add_index "board_design_entries", ["part_number_id"], :name => "part_number_id"
  add_index "board_design_entries", ["design_id"], :name => "design_id"

  create_table "board_design_entry_users", :force => true do |t|
    t.integer "board_design_entry_id", :limit => 12, :default => 0, :null => false
    t.integer "required",              :limit => 3,  :default => 1, :null => false
    t.integer "user_id",               :limit => 12, :default => 0, :null => false
    t.integer "role_id",               :limit => 12, :default => 0, :null => false
  end

  add_index "board_design_entry_users", ["board_design_entry_id"], :name => "board_design_entry_id"

  create_table "board_reviewers", :force => true do |t|
    t.integer "board_id",    :limit => 12, :default => 0, :null => false
    t.integer "reviewer_id", :limit => 12, :default => 0, :null => false
    t.integer "role_id",     :limit => 12, :default => 0, :null => false
  end

  add_index "board_reviewers", ["board_id"], :name => "board_id"

  create_table "boards", :force => true do |t|
    t.string  "name",        :limit => 16, :default => "''", :null => false
    t.integer "prefix_id",   :limit => 3,  :default => 0,    :null => false
    t.string  "number",      :limit => 3,  :default => "",   :null => false
    t.integer "platform_id", :limit => 3,  :default => 0,    :null => false
    t.integer "project_id",  :limit => 3,  :default => 0,    :null => false
    t.string  "description", :limit => 80, :default => "",   :null => false
    t.integer "active",      :limit => 3,  :default => 0,    :null => false
  end

  add_index "boards", ["prefix_id"], :name => "prefix_id"

  create_table "boards_fab_houses", :id => false, :force => true do |t|
    t.integer "board_id",     :limit => 12, :default => 0, :null => false
    t.integer "fab_house_id", :limit => 3,  :default => 0, :null => false
  end

  add_index "boards_fab_houses", ["board_id"], :name => "board_id"
  add_index "boards_fab_houses", ["fab_house_id"], :name => "fab_house_id"

  create_table "boards_users", :id => false, :force => true do |t|
    t.integer "board_id", :limit => 12, :default => 0, :null => false
    t.integer "user_id",  :limit => 12, :default => 0, :null => false
  end

  add_index "boards_users", ["board_id"], :name => "board_id"
  add_index "boards_users", ["user_id"], :name => "user_id"

  create_table "cc_list_histories", :force => true do |t|
    t.integer  "design_review_id", :limit => 12, :default => 0,  :null => false
    t.integer  "user_id",          :limit => 12, :default => 0,  :null => false
    t.integer  "addressee_id",     :limit => 12, :default => 0,  :null => false
    t.string   "action",           :limit => 8,  :default => "", :null => false
    t.datetime "created_on"
  end

  create_table "change_classes", :force => true do |t|
    t.string   "name"
    t.integer  "position",     :limit => 11
    t.integer  "manager_only", :limit => 1,  :default => 0, :null => false
    t.boolean  "active"
    t.text     "definition"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "change_details", :force => true do |t|
    t.string   "name"
    t.integer  "position",       :limit => 11
    t.integer  "change_item_id", :limit => 11
    t.boolean  "active"
    t.text     "definition"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "change_items", :force => true do |t|
    t.string   "name"
    t.integer  "position",       :limit => 11
    t.integer  "change_type_id", :limit => 11
    t.boolean  "active"
    t.text     "definition"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "change_types", :force => true do |t|
    t.string   "name"
    t.integer  "position",        :limit => 11
    t.integer  "change_class_id", :limit => 11
    t.boolean  "active"
    t.text     "definition"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "checklists", :force => true do |t|
    t.integer  "major_rev_number",                  :limit => 3,  :default => 0, :null => false
    t.integer  "minor_rev_number",                  :limit => 3,  :default => 0, :null => false
    t.integer  "released",                          :limit => 3,  :default => 0, :null => false
    t.integer  "used",                              :limit => 3,  :default => 0, :null => false
    t.datetime "released_on"
    t.integer  "released_by",                       :limit => 12, :default => 0, :null => false
    t.datetime "created_on"
    t.integer  "created_by",                        :limit => 12, :default => 0, :null => false
    t.integer  "designer_only_count",               :limit => 3,  :default => 0, :null => false
    t.integer  "designer_auditor_count",            :limit => 3,  :default => 0, :null => false
    t.integer  "dc_designer_only_count",            :limit => 3,  :default => 0, :null => false
    t.integer  "dc_designer_auditor_count",         :limit => 3,  :default => 0, :null => false
    t.integer  "dr_designer_only_count",            :limit => 3,  :default => 0, :null => false
    t.integer  "dr_designer_auditor_count",         :limit => 3,  :default => 0, :null => false
    t.integer  "new_design_self_check_count",       :limit => 12, :default => 0, :null => false
    t.integer  "new_design_peer_check_count",       :limit => 12, :default => 0, :null => false
    t.integer  "bareboard_design_self_check_count", :limit => 12, :default => 0, :null => false
    t.integer  "bareboard_design_peer_check_count", :limit => 12, :default => 0, :null => false
  end

  create_table "checks", :force => true do |t|
    t.integer "section_id",      :limit => 12,  :default => 0,    :null => false
    t.integer "subsection_id",   :limit => 12,  :default => 0,    :null => false
    t.string  "title",           :limit => 64,  :default => "''", :null => false
    t.text    "check",                                            :null => false
    t.string  "url",             :limit => 250, :default => "",   :null => false
    t.integer "full_review",     :limit => 3,   :default => 0,    :null => false
    t.integer "date_code_check", :limit => 3,   :default => 0,    :null => false
    t.integer "dot_rev_check",   :limit => 3,   :default => 0,    :null => false
    t.integer "position",        :limit => 6,   :default => 0,    :null => false
    t.string  "check_type",      :limit => 16,  :default => "''", :null => false
  end

  add_index "checks", ["subsection_id"], :name => "subsection_id"

  create_table "design_centers", :force => true do |t|
    t.string  "name",     :limit => 32, :default => "", :null => false
    t.string  "pcb_path", :limit => 64, :default => "", :null => false
    t.string  "hw_path",  :limit => 64, :default => "", :null => false
    t.integer "active",   :limit => 3,  :default => 0,  :null => false
  end

  create_table "design_changes", :force => true do |t|
    t.integer  "design_id",        :limit => 11, :default => 0
    t.integer  "change_detail_id", :limit => 11, :default => 0
    t.integer  "change_item_id",   :limit => 11, :default => 0
    t.integer  "change_type_id",   :limit => 11, :default => 0
    t.integer  "change_class_id",  :limit => 11, :default => 0
    t.integer  "designer_id",      :limit => 11, :default => 0
    t.integer  "manager_id",       :limit => 11, :default => 0
    t.boolean  "approved",                       :default => false
    t.float    "hours",                          :default => 0.0
    t.string   "impact",           :limit => 8,  :default => "None"
    t.datetime "approved_at"
    t.text     "designer_comment"
    t.text     "manager_comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "design_checks", :force => true do |t|
    t.integer  "audit_id",            :limit => 12, :default => 0,      :null => false
    t.integer  "check_id",            :limit => 12, :default => 0,      :null => false
    t.integer  "auditor_id",          :limit => 12, :default => 0,      :null => false
    t.string   "auditor_result",      :limit => 10, :default => "None", :null => false
    t.datetime "auditor_checked_on"
    t.integer  "designer_id",         :limit => 12, :default => 0,      :null => false
    t.string   "designer_result",     :limit => 10, :default => "None", :null => false
    t.datetime "designer_checked_on"
  end

  add_index "design_checks", ["audit_id"], :name => "audit_id"
  add_index "design_checks", ["check_id"], :name => "check_id"

  create_table "design_directories", :force => true do |t|
    t.string  "name",   :limit => 64, :default => "", :null => false
    t.integer "active", :limit => 3,  :default => 1,  :null => false
  end

  create_table "design_review_comments", :force => true do |t|
    t.integer  "design_review_id", :limit => 12, :default => 0, :null => false
    t.integer  "user_id",          :limit => 12, :default => 0, :null => false
    t.datetime "created_on"
    t.integer  "highlight",        :limit => 3,  :default => 0, :null => false
    t.text     "comment",                                       :null => false
  end

  create_table "design_review_documents", :force => true do |t|
    t.integer "board_id",         :limit => 12, :default => 0, :null => false
    t.integer "design_id",        :limit => 12, :default => 0, :null => false
    t.integer "document_type_id", :limit => 3,  :default => 0, :null => false
    t.integer "document_id",      :limit => 12, :default => 0, :null => false
  end

  add_index "design_review_documents", ["board_id"], :name => "board_id"

  create_table "design_review_results", :force => true do |t|
    t.integer  "design_review_id", :limit => 12, :default => 0,      :null => false
    t.integer  "reviewer_id",      :limit => 12, :default => 0,      :null => false
    t.integer  "role_id",          :limit => 12, :default => 0,      :null => false
    t.string   "result",           :limit => 16, :default => "NONE", :null => false
    t.datetime "reviewed_on"
  end

  add_index "design_review_results", ["design_review_id"], :name => "design_review_id"

  create_table "design_reviews", :force => true do |t|
    t.integer  "posting_count",      :limit => 3,  :default => 0, :null => false
    t.integer  "design_id",          :limit => 12, :default => 0, :null => false
    t.integer  "designer_id",        :limit => 12, :default => 0, :null => false
    t.integer  "design_center_id",   :limit => 3,  :default => 0, :null => false
    t.integer  "review_status_id",   :limit => 3,  :default => 0, :null => false
    t.integer  "review_type_id",     :limit => 3,  :default => 0, :null => false
    t.integer  "review_type_id_2",   :limit => 3,  :default => 0, :null => false
    t.integer  "priority_id",        :limit => 3,  :default => 0, :null => false
    t.integer  "creator_id",         :limit => 12, :default => 0, :null => false
    t.integer  "total_time_on_hold", :limit => 12, :default => 0, :null => false
    t.datetime "created_on"
    t.datetime "placed_on_hold_on"
    t.datetime "reposted_on"
    t.datetime "completed_on"
  end

  add_index "design_reviews", ["design_id"], :name => "design_id"

  create_table "design_updates", :force => true do |t|
    t.integer  "design_id",        :limit => 12, :default => 0,  :null => false
    t.integer  "design_review_id", :limit => 12, :default => 0,  :null => false
    t.integer  "user_id",          :limit => 12, :default => 0,  :null => false
    t.string   "what",             :limit => 32, :default => "", :null => false
    t.string   "old_value",        :limit => 32, :default => "", :null => false
    t.string   "new_value",        :limit => 32, :default => "", :null => false
    t.datetime "created_on"
  end

  add_index "design_updates", ["design_id"], :name => "design_id"
  add_index "design_updates", ["design_review_id"], :name => "design_review_id"

  create_table "designs", :force => true do |t|
    t.string   "name",             :limit => 12, :default => "",   :null => false
    t.integer  "part_number_id",   :limit => 12, :default => 0,    :null => false
    t.integer  "design_center_id", :limit => 11, :default => 0,    :null => false
    t.integer  "phase_id",         :limit => 3,  :default => 0,    :null => false
    t.integer  "priority_id",      :limit => 3,  :default => 0,    :null => false
    t.integer  "board_id",         :limit => 12, :default => 0,    :null => false
    t.integer  "revision_id",      :limit => 3,  :default => 0,    :null => false
    t.integer  "suffix_id",        :limit => 3,  :default => 0
    t.integer  "numeric_revision", :limit => 3,  :default => 0,    :null => false
    t.string   "eco_number",       :limit => 10, :default => ""
    t.string   "design_type",      :limit => 15, :default => "''", :null => false
    t.integer  "designer_id",      :limit => 12, :default => 0,    :null => false
    t.integer  "peer_id",          :limit => 12, :default => 0,    :null => false
    t.integer  "pcb_input_id",     :limit => 12, :default => 0,    :null => false
    t.datetime "created_on"
    t.integer  "created_by",       :limit => 12, :default => 0,    :null => false
  end

  create_table "designs_fab_houses", :id => false, :force => true do |t|
    t.integer "design_id",    :limit => 12, :default => 0, :null => false
    t.integer "fab_house_id", :limit => 3,  :default => 0, :null => false
  end

  add_index "designs_fab_houses", ["design_id"], :name => "design_id"
  add_index "designs_fab_houses", ["fab_house_id"], :name => "fab_house_id"

  create_table "display_fields", :force => true do |t|
    t.string "name", :limit => 16, :default => "", :null => false
  end

  create_table "divisions", :force => true do |t|
    t.string  "name",   :limit => 32, :default => "", :null => false
    t.integer "active", :limit => 3,  :default => 0,  :null => false
  end

  create_table "document_types", :force => true do |t|
    t.string  "name",     :limit => 16, :default => "", :null => false
    t.integer "required", :limit => 3,  :default => 0,  :null => false
    t.integer "active",   :limit => 3,  :default => 0,  :null => false
  end

  create_table "documents", :force => true do |t|
    t.binary   "data",         :limit => 16777215,                 :null => false
    t.integer  "unpacked",     :limit => 3,        :default => 1,  :null => false
    t.string   "name",         :limit => 100,      :default => "", :null => false
    t.string   "content_type", :limit => 100,      :default => "", :null => false
    t.integer  "created_by",   :limit => 12,       :default => 0,  :null => false
    t.datetime "created_on"
  end

  create_table "eco_comments", :force => true do |t|
    t.integer  "eco_task_id", :limit => 11, :default => 0, :null => false
    t.integer  "user_id",     :limit => 11, :default => 0, :null => false
    t.datetime "created_at"
    t.text     "comment"
  end

  create_table "eco_documents", :force => true do |t|
    t.integer  "unpacked",      :limit => 3,          :default => 0,     :null => false
    t.string   "name",          :limit => 100,        :default => "",    :null => false
    t.string   "content_type",  :limit => 100,        :default => "",    :null => false
    t.integer  "user_id",       :limit => 11,         :default => 0,     :null => false
    t.integer  "eco_task_id",   :limit => 11,         :default => 0,     :null => false
    t.datetime "created_at"
    t.boolean  "specification",                       :default => false
    t.binary   "data",          :limit => 2147483647,                    :null => false
  end

  create_table "eco_tasks", :force => true do |t|
    t.string   "number",           :limit => 16
    t.string   "pcb_revision",     :limit => 2
    t.string   "pcba_part_number", :limit => 10
    t.string   "directory_name",   :limit => 40
    t.integer  "eco_type_id",      :limit => 11
    t.boolean  "completed",                      :default => false, :null => false
    t.boolean  "closed",                         :default => false, :null => false
    t.boolean  "specified",                      :default => false, :null => false
    t.boolean  "cuts_and_jumps",                 :default => false, :null => false
    t.text     "document_link"
    t.datetime "screened_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "closed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "eco_tasks_eco_types", :id => false, :force => true do |t|
    t.integer "eco_task_id", :limit => 11, :default => 0, :null => false
    t.integer "eco_type_id", :limit => 11, :default => 0, :null => false
  end

  create_table "eco_tasks_users", :id => false, :force => true do |t|
    t.integer "eco_task_id", :limit => 11, :default => 0, :null => false
    t.integer "user_id",     :limit => 11, :default => 0, :null => false
  end

  create_table "eco_types", :force => true do |t|
    t.string  "name"
    t.boolean "active"
  end

  create_table "fab_houses", :force => true do |t|
    t.string  "name",   :limit => 32, :default => "", :null => false
    t.integer "active", :limit => 3,  :default => 0,  :null => false
  end

  create_table "ftp_notifications", :force => true do |t|
    t.integer  "design_id",           :limit => 12, :default => 0,  :null => false
    t.integer  "division_id",         :limit => 3,  :default => 0,  :null => false
    t.integer  "design_center_id",    :limit => 3,  :default => 0,  :null => false
    t.integer  "fab_house_id",        :limit => 3,  :default => 0,  :null => false
    t.string   "assembly_bom_number", :limit => 32, :default => "", :null => false
    t.string   "file_data",           :limit => 64, :default => "", :null => false
    t.string   "revision_date",       :limit => 8,  :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ftp_notifications", ["design_id"], :name => "design_id"

  create_table "incoming_directories", :force => true do |t|
    t.string  "name",   :limit => 64, :default => "", :null => false
    t.integer "active", :limit => 3,  :default => 1,  :null => false
  end

  create_table "ipd_posts", :force => true do |t|
    t.integer  "root_id",    :limit => 12, :default => 0,  :null => false
    t.integer  "parent_id",  :limit => 12, :default => 0,  :null => false
    t.integer  "depth",      :limit => 12, :default => 0,  :null => false
    t.integer  "lft",        :limit => 12, :default => 0,  :null => false
    t.integer  "rgt",        :limit => 12, :default => 0,  :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "design_id",  :limit => 12, :default => 0,  :null => false
    t.integer  "user_id",    :limit => 12, :default => 0,  :null => false
    t.string   "subject",                  :default => "", :null => false
    t.text     "body",                                     :null => false
  end

  add_index "ipd_posts", ["lft", "rgt"], :name => "lft"
  add_index "ipd_posts", ["design_id"], :name => "design_id"

  create_table "ipd_posts_users", :id => false, :force => true do |t|
    t.integer "ipd_post_id", :limit => 12, :default => 0, :null => false
    t.integer "user_id",     :limit => 12, :default => 0, :null => false
  end

  add_index "ipd_posts_users", ["ipd_post_id"], :name => "ipd_post_id"
  add_index "ipd_posts_users", ["user_id"], :name => "user_id"

  create_table "locations", :force => true do |t|
    t.string  "name",   :limit => 32, :default => "", :null => false
    t.integer "active", :limit => 3,  :default => 0,  :null => false
  end

  create_table "oi_assignment_comments", :force => true do |t|
    t.integer  "oi_assignment_id", :limit => 12, :default => 0, :null => false
    t.integer  "user_id",          :limit => 12, :default => 0, :null => false
    t.datetime "created_on"
    t.text     "comment",                                       :null => false
  end

  add_index "oi_assignment_comments", ["oi_assignment_id"], :name => "oi_assignment_id"

  create_table "oi_assignment_reports", :force => true do |t|
    t.integer  "oi_assignment_id", :limit => 12, :default => 0, :null => false
    t.integer  "score",            :limit => 3,  :default => 0, :null => false
    t.integer  "user_id",          :limit => 12, :default => 0, :null => false
    t.datetime "created_on"
    t.text     "comment",                                       :null => false
  end

  add_index "oi_assignment_reports", ["oi_assignment_id"], :name => "oi_assignment_id"
  add_index "oi_assignment_reports", ["user_id"], :name => "user_id"

  create_table "oi_assignments", :force => true do |t|
    t.integer  "oi_instruction_id", :limit => 12, :default => 0, :null => false
    t.integer  "user_id",           :limit => 12, :default => 0, :null => false
    t.integer  "complexity_id",     :limit => 3,  :default => 0, :null => false
    t.datetime "created_on"
    t.integer  "cc_hw_engineer",    :limit => 3,  :default => 0, :null => false
    t.integer  "complete",          :limit => 3,  :default => 0, :null => false
    t.datetime "completed_on"
    t.datetime "due_date"
  end

  add_index "oi_assignments", ["oi_instruction_id"], :name => "oi_instruction_id"

  create_table "oi_categories", :force => true do |t|
    t.string "name",  :limit => 32, :default => "", :null => false
    t.string "label", :limit => 16, :default => "", :null => false
  end

  create_table "oi_category_sections", :force => true do |t|
    t.string  "name",                                :default => "", :null => false
    t.string  "url1_name",            :limit => 32,  :default => "", :null => false
    t.string  "url1",                 :limit => 128, :default => "", :null => false
    t.string  "url2_name",            :limit => 32,  :default => "", :null => false
    t.string  "url2",                 :limit => 128, :default => "", :null => false
    t.string  "url3_name",            :limit => 32,  :default => "", :null => false
    t.string  "url3",                 :limit => 128, :default => "", :null => false
    t.text    "instructions",                                        :null => false
    t.integer "oi_category_id",       :limit => 12,  :default => 0,  :null => false
    t.integer "allegro_board_symbol", :limit => 3,   :default => 0,  :null => false
    t.integer "outline_drawing_link", :limit => 3,   :default => 0,  :null => false
  end

  add_index "oi_category_sections", ["oi_category_id"], :name => "oi_category_id"

  create_table "oi_instructions", :force => true do |t|
    t.integer  "design_id",              :limit => 12, :default => 0,  :null => false
    t.integer  "oi_category_section_id", :limit => 12, :default => 0,  :null => false
    t.integer  "user_id",                :limit => 12, :default => 0,  :null => false
    t.datetime "created_on"
    t.integer  "complete",               :limit => 3,  :default => 0,  :null => false
    t.datetime "completed_on"
    t.string   "allegro_board_symbol",   :limit => 32, :default => "", :null => false
    t.string   "details",                :limit => 1,  :default => "", :null => false
  end

  add_index "oi_instructions", ["design_id"], :name => "design_id"
  add_index "oi_instructions", ["oi_category_section_id"], :name => "oi_category_section_id"
  add_index "oi_instructions", ["user_id"], :name => "user_id"

  create_table "part_numbers", :force => true do |t|
    t.string "pcb_prefix",       :limit => 3, :default => "", :null => false
    t.string "pcb_number",       :limit => 3, :default => "", :null => false
    t.string "pcb_dash_number",  :limit => 2, :default => "", :null => false
    t.string "pcb_revision",     :limit => 1, :default => "", :null => false
    t.string "pcba_prefix",      :limit => 3, :default => "", :null => false
    t.string "pcba_number",      :limit => 3, :default => "", :null => false
    t.string "pcba_dash_number", :limit => 2, :default => "", :null => false
    t.string "pcba_revision",    :limit => 1, :default => "", :null => false
  end

  create_table "part_nums", :force => true do |t|
    t.string  "prefix",                :limit => 3
    t.string  "number",                :limit => 3
    t.string  "dash",                  :limit => 2
    t.string  "revision",              :limit => 1
    t.string  "use",                   :limit => 5
    t.integer "board_design_entry_id", :limit => 11
    t.integer "design_id",             :limit => 11
  end

  create_table "permissions", :force => true do |t|
    t.string "name", :limit => 32, :default => "", :null => false
  end

  create_table "permissions_roles", :id => false, :force => true do |t|
    t.integer "permission_id", :limit => 12, :default => 0, :null => false
    t.integer "role_id",       :limit => 12, :default => 0, :null => false
  end

  create_table "platforms", :force => true do |t|
    t.integer "active", :limit => 3,  :default => 0,  :null => false
    t.string  "name",   :limit => 32, :default => "", :null => false
  end

  create_table "posting_timestamps", :id => false, :force => true do |t|
    t.integer  "design_review_id", :limit => 11
    t.datetime "posted_at"
  end

  create_table "prefixes", :force => true do |t|
    t.string  "pcb_mnemonic",    :limit => 4, :default => "''", :null => false
    t.string  "loaded_prefix",   :limit => 4, :default => "''", :null => false
    t.string  "unloaded_prefix", :limit => 4, :default => "''", :null => false
    t.integer "active",          :limit => 3, :default => 0,    :null => false
  end

  create_table "priorities", :force => true do |t|
    t.integer "value", :limit => 3,  :default => 0,  :null => false
    t.string  "name",  :limit => 16, :default => "", :null => false
  end

  create_table "product_types", :force => true do |t|
    t.string  "name",   :limit => 64, :default => "", :null => false
    t.integer "active", :limit => 3,  :default => 1,  :null => false
  end

  create_table "projects", :force => true do |t|
    t.string  "name",   :limit => 32, :default => "", :null => false
    t.integer "active", :limit => 3,  :default => 0,  :null => false
  end

  create_table "review_groups", :force => true do |t|
    t.string  "name",     :limit => 16, :default => "", :null => false
    t.integer "active",   :limit => 3,  :default => 0,  :null => false
    t.integer "cc_peers", :limit => 3,  :default => 0,  :null => false
  end

  create_table "review_status", :force => true do |t|
    t.string  "name",   :limit => 16, :default => "", :null => false
    t.integer "active", :limit => 3,  :default => 0,  :null => false
  end

  create_table "review_statuses", :force => true do |t|
    t.string  "name",   :limit => 24, :default => "", :null => false
    t.integer "active", :limit => 3,  :default => 0,  :null => false
  end

  create_table "review_types", :force => true do |t|
    t.integer "sort_order", :limit => 3,  :default => 0,  :null => false
    t.string  "name",       :limit => 32, :default => "", :null => false
    t.integer "active",     :limit => 3,  :default => 0,  :null => false
    t.integer "required",   :limit => 3,  :default => 0,  :null => false
  end

  create_table "review_types_roles", :id => false, :force => true do |t|
    t.integer "role_id",        :limit => 12, :default => 0, :null => false
    t.integer "review_type_id", :limit => 3,  :default => 0, :null => false
  end

  add_index "review_types_roles", ["role_id"], :name => "role_id"
  add_index "review_types_roles", ["review_type_id"], :name => "review_type_id"

  create_table "revisions", :force => true do |t|
    t.string "name", :limit => 1, :default => "", :null => false
  end

  create_table "roles", :force => true do |t|
    t.string  "name",                        :limit => 32, :default => "", :null => false
    t.string  "display_name",                :limit => 64, :default => "", :null => false
    t.integer "active",                      :limit => 3,  :default => 0,  :null => false
    t.integer "reviewer",                    :limit => 3,  :default => 0,  :null => false
    t.integer "manager",                     :limit => 3,  :default => 0,  :null => false
    t.integer "cc_peers",                    :limit => 3,  :default => 0,  :null => false
    t.integer "new_design_type",             :limit => 3,  :default => 0,  :null => false
    t.integer "date_code_design_type",       :limit => 3,  :default => 0,  :null => false
    t.integer "dot_rev_design_type",         :limit => 3,  :default => 0,  :null => false
    t.integer "new_design_review_role",      :limit => 3,  :default => 1,  :null => false
    t.integer "bare_board_only_review_role", :limit => 3,  :default => 1,  :null => false
    t.integer "default_reviewer_id",         :limit => 12, :default => 0,  :null => false
  end

  add_index "roles", ["name"], :name => "name"

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id", :limit => 12, :default => 0, :null => false
    t.integer "user_id", :limit => 12, :default => 0, :null => false
  end

  add_index "roles_users", ["role_id"], :name => "role_id"
  add_index "roles_users", ["user_id"], :name => "user_id"

  create_table "sections", :force => true do |t|
    t.integer "checklist_id",     :limit => 12, :default => 0,        :null => false
    t.string  "name"
    t.string  "url",                            :default => "",       :null => false
    t.string  "background_color", :limit => 6,  :default => "FFFFFF", :null => false
    t.integer "position",         :limit => 3,  :default => 0,        :null => false
    t.integer "date_code_check",  :limit => 3,  :default => 0,        :null => false
    t.integer "dot_rev_check",    :limit => 3,  :default => 0,        :null => false
    t.integer "full_review",      :limit => 3,  :default => 0,        :null => false
  end

  add_index "sections", ["checklist_id"], :name => "checklist_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id",                       :default => "", :null => false
    t.text     "data",       :limit => 2147483647
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "subsections", :force => true do |t|
    t.integer "checklist_id",    :limit => 12, :default => 0,  :null => false
    t.integer "section_id",      :limit => 12, :default => 0,  :null => false
    t.string  "name",                          :default => "", :null => false
    t.string  "note",                          :default => "", :null => false
    t.string  "url",                           :default => "", :null => false
    t.integer "position",        :limit => 3,  :default => 0,  :null => false
    t.integer "date_code_check", :limit => 3,  :default => 0,  :null => false
    t.integer "dot_rev_check",   :limit => 3,  :default => 0,  :null => false
    t.integer "full_review",     :limit => 3,  :default => 0,  :null => false
  end

  add_index "subsections", ["section_id"], :name => "section_id"

  create_table "suffixes", :force => true do |t|
    t.string "name", :limit => 1, :default => "", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "login",            :limit => 80
    t.string   "first_name",       :limit => 32
    t.string   "last_name",        :limit => 32
    t.integer  "employee",         :limit => 3,  :default => 1,  :null => false
    t.integer  "design_center_id", :limit => 3,  :default => 0
    t.integer  "active_role_id",   :limit => 12, :default => 0,  :null => false
    t.string   "email",            :limit => 60, :default => "", :null => false
    t.string   "password",         :limit => 40
    t.string   "passwd",           :limit => 40
    t.integer  "active",           :limit => 3,  :default => 0,  :null => false
    t.integer  "division_id",      :limit => 3,  :default => 0,  :null => false
    t.integer  "location_id",      :limit => 3,  :default => 0,  :null => false
    t.integer  "invited",          :limit => 3,  :default => 0,  :null => false
    t.datetime "created_on"
    t.datetime "updated_on"
    t.datetime "access"
  end

end
