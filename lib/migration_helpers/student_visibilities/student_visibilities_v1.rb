# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module MigrationHelpers::StudentVisibilities::StudentVisibilitiesV1
  def self.view(view_name, table_name, is_assignment: false)
    <<~SQL.squish
      CREATE OR REPLACE VIEW #{view_name} AS
      SELECT DISTINCT a.id as #{quiz_or_assignment(is_assignment)},
          e.user_id as user_id,
          e.course_id as course_id
      FROM #{table_name} a
      JOIN #{Enrollment.quoted_table_name} e
          ON e.course_id = a.context_id
          AND a.context_type = 'Course'
          AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
          AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      WHERE a.workflow_state NOT IN ('deleted','unpublished')
          AND COALESCE(a.only_visible_to_overrides, 'false') = 'false'

      UNION

      SELECT DISTINCT a.id as #{quiz_or_assignment(is_assignment)},
          e.user_id as user_id,
          e.course_id as course_id
      FROM #{table_name} a
      JOIN #{Enrollment.quoted_table_name} e
          ON e.course_id = a.context_id
          AND a.context_type = 'Course'
          AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
          AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      INNER JOIN #{AssignmentOverride.quoted_table_name} ao
          ON a.id = ao.#{quiz_or_assignment(is_assignment)}
          AND ao.set_type = 'ADHOC'
      INNER JOIN #{AssignmentOverrideStudent.quoted_table_name} aos
          ON ao.id = aos.assignment_override_id
          AND aos.user_id = e.user_id
      WHERE ao.workflow_state = 'active'
          AND aos.workflow_state <> 'deleted'
          AND a.workflow_state NOT IN ('deleted','unpublished')
          AND a.only_visible_to_overrides = 'true'

      UNION

      #{group_overrides(is_assignment)}

      SELECT DISTINCT a.id as #{quiz_or_assignment(is_assignment)},
          e.user_id as user_id,
          e.course_id as course_id
      FROM #{table_name} a
      JOIN #{Enrollment.quoted_table_name} e
          ON e.course_id = a.context_id
          AND a.context_type = 'Course'
          AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
          AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      INNER JOIN #{AssignmentOverride.quoted_table_name} ao
          ON e.course_section_id = ao.set_id
          AND ao.set_type = 'CourseSection'
          AND ao.#{quiz_or_assignment(is_assignment)} = a.id
      WHERE a.workflow_state NOT IN ('deleted','unpublished')
          AND a.only_visible_to_overrides = 'true'
          AND ao.workflow_state = 'active'
    SQL
  end

  def self.group_overrides(is_assignment)
    if is_assignment
      "SELECT DISTINCT a.id as assignment_id,
            e.user_id as user_id,
            e.course_id as course_id
      FROM #{Assignment.quoted_table_name} a
      JOIN #{Enrollment.quoted_table_name} e
            ON e.course_id = a.context_id
            AND a.context_type = 'Course'
            AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
            AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      INNER JOIN #{AssignmentOverride.quoted_table_name} ao
            ON a.id = ao.assignment_id
            AND ao.set_type = 'Group'
      INNER JOIN #{Group.quoted_table_name} g
            ON g.id = ao.set_id
      INNER JOIN #{GroupMembership.quoted_table_name} gm
            ON gm.group_id = g.id
            AND gm.user_id = e.user_id
      WHERE gm.workflow_state <> 'deleted'
            AND g.workflow_state <> 'deleted'
            AND ao.workflow_state = 'active'
            AND a.workflow_state NOT IN ('deleted','unpublished')
            AND a.only_visible_to_overrides = 'true'

      UNION"
    else
      ""
    end
  end

  def self.quiz_or_assignment(is_assignment)
    if is_assignment
      "assignment_id"
    else
      "quiz_id"
    end
  end
end
