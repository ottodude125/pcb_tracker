CREATE TABLE `audit_comments` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `design_check_id` int(12) unsigned NOT NULL default '0',
  `user_id` int(12) unsigned NOT NULL default '0',
  `created_on` timestamp(14) NOT NULL,
  `comment` text NOT NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `audits` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `design_id` int(12) unsigned NOT NULL default '0',
  `checklist_id` int(12) unsigned NOT NULL default '0',
  `designer_complete` tinyint(3) unsigned NOT NULL default '0',
  `auditor_complete` tinyint(3) unsigned NOT NULL default '0',
  `designer_completed_checks` tinyint(3) unsigned NOT NULL default '0',
  `auditor_completed_checks` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `board_reviewers` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `board_id` int(12) unsigned NOT NULL default '0',
  `reviewer_id` int(12) unsigned NOT NULL default '0',
  `role_id` int(12) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `boards` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `name` char(16) NOT NULL default '''''',
  `prefix_id` tinyint(3) unsigned NOT NULL default '0',
  `number` char(3) NOT NULL default '',
  `platform_id` tinyint(3) unsigned NOT NULL default '0',
  `project_id` tinyint(3) unsigned NOT NULL default '0',
  `active` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `boards_fab_houses` (
  `board_id` int(12) unsigned NOT NULL default '0',
  `fab_house_id` tinyint(3) unsigned NOT NULL default '0'
) TYPE=InnoDB;

CREATE TABLE `boards_users` (
  `board_id` int(12) unsigned NOT NULL default '0',
  `user_id` int(12) unsigned NOT NULL default '0'
) TYPE=InnoDB;

CREATE TABLE `cc_list_histories` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `design_review_id` int(12) unsigned NOT NULL default '0',
  `user_id` int(12) unsigned NOT NULL default '0',
  `addressee_id` int(12) unsigned NOT NULL default '0',
  `action` char(8) NOT NULL default '',
  `created_on` timestamp(14) NOT NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `checklists` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `major_rev_number` tinyint(3) unsigned NOT NULL default '0',
  `minor_rev_number` tinyint(3) unsigned NOT NULL default '0',
  `released` tinyint(3) unsigned NOT NULL default '0',
  `used` tinyint(3) unsigned NOT NULL default '0',
  `released_on` timestamp(14) NOT NULL,
  `released_by` int(12) unsigned NOT NULL default '0',
  `created_on` timestamp(14) NOT NULL,
  `created_by` int(12) unsigned NOT NULL default '0',
  `designer_only_count` tinyint(3) unsigned NOT NULL default '0',
  `designer_auditor_count` tinyint(3) unsigned NOT NULL default '0',
  `dc_designer_only_count` tinyint(3) unsigned NOT NULL default '0',
  `dc_designer_auditor_count` tinyint(3) unsigned NOT NULL default '0',
  `dr_designer_only_count` tinyint(3) unsigned NOT NULL default '0',
  `dr_designer_auditor_count` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `checks` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `section_id` int(12) unsigned NOT NULL default '0',
  `subsection_id` int(12) unsigned NOT NULL default '0',
  `title` varchar(64) NOT NULL default '''''',
  `check` text NOT NULL,
  `url` varchar(250) NOT NULL default '',
  `full_review` tinyint(3) unsigned NOT NULL default '0',
  `date_code_check` tinyint(3) unsigned NOT NULL default '0',
  `dot_rev_check` tinyint(3) unsigned NOT NULL default '0',
  `sort_order` smallint(6) unsigned NOT NULL default '0',
  `check_type` varchar(16) NOT NULL default '''''',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `design_centers` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `name` varchar(32) NOT NULL default '',
  `pcb_path` varchar(64) NOT NULL default '',
  `hw_path` varchar(64) NOT NULL default '',
  `active` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `design_checks` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `audit_id` int(12) unsigned NOT NULL default '0',
  `check_id` int(12) unsigned NOT NULL default '0',
  `auditor_id` int(12) unsigned NOT NULL default '0',
  `auditor_result` char(10) NOT NULL default 'None',
  `auditor_checked_on` timestamp(14) NOT NULL,
  `designer_id` int(12) unsigned NOT NULL default '0',
  `designer_result` char(10) NOT NULL default 'None',
  `designer_checked_on` timestamp(14) NOT NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `design_review_comments` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `design_review_id` int(12) unsigned NOT NULL default '0',
  `user_id` int(12) unsigned NOT NULL default '0',
  `created_on` timestamp(14) NOT NULL,
  `comment` text NOT NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `design_review_documents` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `board_id` int(12) unsigned NOT NULL default '0',
  `design_id` int(12) unsigned NOT NULL default '0',
  `document_type_id` tinyint(3) unsigned NOT NULL default '0',
  `document_id` int(12) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `design_review_results` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `design_review_id` int(12) unsigned NOT NULL default '0',
  `reviewer_id` int(12) unsigned NOT NULL default '0',
  `role_id` int(12) unsigned NOT NULL default '0',
  `result` varchar(16) NOT NULL default 'NONE',
  `reviewed_on` timestamp(14) NOT NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `design_reviews` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `posting_count` tinyint(3) unsigned NOT NULL default '0',
  `design_id` int(12) unsigned NOT NULL default '0',
  `designer_id` int(12) unsigned NOT NULL default '0',
  `design_center_id` tinyint(3) unsigned NOT NULL default '0',
  `review_status_id` tinyint(3) unsigned NOT NULL default '0',
  `review_type_id` tinyint(3) unsigned NOT NULL default '0',
  `review_type_id_2` tinyint(3) unsigned NOT NULL default '0',
  `priority_id` tinyint(3) unsigned NOT NULL default '0',
  `creator_id` int(12) unsigned NOT NULL default '0',
  `created_on` timestamp(14) NOT NULL,
  `reposted_on` timestamp(14) NOT NULL,
  `completed_on` timestamp(14) NOT NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `designs` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `name` varchar(12) NOT NULL default '',
  `priority_id` tinyint(3) unsigned NOT NULL default '0',
  `board_id` int(12) unsigned NOT NULL default '0',
  `revision_id` tinyint(3) unsigned NOT NULL default '0',
  `suffix_id` tinyint(3) unsigned default '0',
  `design_type` varchar(15) NOT NULL default '''''',
  `designer_id` int(12) unsigned NOT NULL default '0',
  `peer_id` int(12) unsigned NOT NULL default '0',
  `created_on` timestamp(14) NOT NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `designs_fab_houses` (
  `design_id` int(12) unsigned NOT NULL default '0',
  `fab_house_id` tinyint(3) unsigned NOT NULL default '0'
) TYPE=InnoDB;

CREATE TABLE `display_fields` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `name` char(16) NOT NULL default '',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `divisions` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `name` varchar(16) NOT NULL default '',
  `required` tinyint(3) unsigned NOT NULL default '0',
  `active` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `document_types` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `name` char(16) NOT NULL default '',
  `required` tinyint(3) unsigned NOT NULL default '0',
  `active` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `documents` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `data` longblob NOT NULL,
  `name` varchar(100) NOT NULL default '',
  `content_type` varchar(100) NOT NULL default '',
  `created_by` int(12) unsigned NOT NULL default '0',
  `created_on` timestamp(14) NOT NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `fab_houses` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `name` char(32) NOT NULL default '',
  `active` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `permissions` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `name` varchar(32) NOT NULL default '',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `permissions_roles` (
  `permission_id` int(12) NOT NULL default '0',
  `role_id` int(12) NOT NULL default '0'
) TYPE=InnoDB;

CREATE TABLE `platforms` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `active` tinyint(3) unsigned NOT NULL default '0',
  `name` char(32) NOT NULL default '',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `prefixes` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `pcb_mnemonic` char(4) NOT NULL default '''''',
  `loaded_prefix` char(4) NOT NULL default '''''',
  `unloaded_prefix` char(4) NOT NULL default '''''',
  `active` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `priorities` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `value` tinyint(3) unsigned NOT NULL default '0',
  `name` char(16) NOT NULL default '',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `projects` (
  `id` tinyint(12) unsigned NOT NULL auto_increment,
  `name` char(32) NOT NULL default '',
  `active` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `review_groups` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `name` char(16) NOT NULL default '',
  `active` tinyint(3) unsigned NOT NULL default '0',
  `cc_peers` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `review_status` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `name` char(16) NOT NULL default '',
  `active` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `review_statuses` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `name` char(16) NOT NULL default '',
  `active` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `review_types` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `sort_order` tinyint(3) unsigned NOT NULL default '0',
  `name` char(32) NOT NULL default '',
  `active` tinyint(3) unsigned NOT NULL default '0',
  `required` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `review_types_roles` (
  `role_id` int(12) unsigned NOT NULL default '0',
  `review_type_id` tinyint(3) unsigned NOT NULL default '0',
  KEY `role_id` (`role_id`,`review_type_id`)
) TYPE=InnoDB;

CREATE TABLE `revisions` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `name` char(1) NOT NULL default '',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `roles` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `name` varchar(32) NOT NULL default '',
  `active` tinyint(3) unsigned NOT NULL default '0',
  `reviewer` tinyint(3) unsigned NOT NULL default '0',
  `cc_peers` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `roles_users` (
  `role_id` int(12) NOT NULL default '0',
  `user_id` int(12) NOT NULL default '0'
) TYPE=InnoDB;

CREATE TABLE `sections` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `checklist_id` int(12) unsigned NOT NULL default '0',
  `name` varchar(255) default NULL,
  `url` varchar(255) NOT NULL default '',
  `background_color` varchar(6) NOT NULL default 'FFFFFF',
  `sort_order` tinyint(3) unsigned NOT NULL default '0',
  `date_code_check` tinyint(3) unsigned NOT NULL default '0',
  `dot_rev_check` tinyint(3) unsigned NOT NULL default '0',
  `full_review` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `subsections` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `checklist_id` int(12) unsigned NOT NULL default '0',
  `section_id` int(12) unsigned NOT NULL default '0',
  `name` varchar(255) NOT NULL default '',
  `note` varchar(255) NOT NULL default '',
  `url` varchar(255) NOT NULL default '',
  `sort_order` tinyint(3) unsigned NOT NULL default '0',
  `date_code_check` tinyint(3) unsigned NOT NULL default '0',
  `dot_rev_check` tinyint(3) unsigned NOT NULL default '0',
  `full_review` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `suffixes` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `name` char(1) NOT NULL default '',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `users` (
  `id` int(12) unsigned NOT NULL auto_increment,
  `login` varchar(80) default NULL,
  `first_name` varchar(32) default NULL,
  `last_name` varchar(32) default NULL,
  `design_center_id` tinyint(3) unsigned default '0',
  `email` varchar(60) NOT NULL default '',
  `password` varchar(40) default NULL,
  `active` tinyint(3) unsigned NOT NULL default '0',
  `created_on` timestamp(14) NOT NULL,
  `updated_on` timestamp(14) NOT NULL,
  `access` timestamp(14) NOT NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

