# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
#

class BookmarkedCollection::Proxy < PaginatedCollection::Proxy
  attr_reader :depth

  def initialize(bookmarker, block)
    @bookmarker = bookmarker
    @depth = 0
    super(block)
  end

  def new_pager
    BookmarkedCollection::Collection.new(@bookmarker)
  end

  def configure_pager(pager, options)
    super(pager, options.merge(total_entries: nil))
  end
end
