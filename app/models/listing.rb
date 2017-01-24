class Listing < ActiveRecord::Base
  enum category: {
    'apartment': 0,
    'terrace': 1,
    'bungalow': 2,
    'villa': 3
  }

  filterrific(
    default_filter_params: { sorted_by: 'created_at_desc' },
    available_filters: [
      :sorted_by,
      :search_query,
      :with_title,
      :with_location,
      :with_room_nums
    ]
  )

  scope :with_title, -> (title) { where(title: title) }
  # scope :with_location, -> (location) { where(location: location) }

  scope :with_location, lambda { |locations|
    where(location: [*locations])
  }

  scope :with_room_nums, lambda { |nums|
    where(room_nums: [*nums])
  }


  scope :search_query, lambda { |query|
    terms = query.downcase.split(/\s+/)

    terms = terms.map { |e|
    (e.gsub('*', '%') + '%').gsub(/%+/, '%')
    }

    num_or_conds = 2
      where(
        terms.map { |term|
          "(LOWER(listings.title) LIKE ? OR LOWER(listings.location) LIKE ?)"
        }.join(' AND '),
        *terms.map { |e| [e] * num_or_conds }.flatten
      )

  }


  scope :sorted_by, lambda { |sort_option|
    # extract the sort direction from the param value.
    direction = (sort_option =~ /desc$/) ? 'desc' : 'asc'
    case sort_option.to_s
    when /^created_at_/
      # Simple sort on the created_at column.
      # Make sure to include the table name to avoid ambiguous column names.
      # Joining on other tables is quite common in Filterrific, and almost
      # every ActiveRecord table has a 'created_at' column.
      order("listings.created_at #{ direction }")
    when /^title_/
      # Simple sort on the name colums
      order("LOWER(listings.title) #{ direction }")
    else
      raise(ArgumentError, "Invalid sort option: #{ sort_option.inspect }")
    end
  }

  def self.options_for_sorted_by
      [
        ['title (a-z)', 'title_asc'],
        ['title (z-a)', 'title_desc'],
        ['Posted date (newest first)', 'created_at_desc'],
        ['Posted date (oldest first)', 'created_at_asc']
      ]
  end

  def self.options_for_with_title
      [
        ['Name (a-z)', 'name_asc'],
        ['Registration date (newest first)', 'created_at_desc'],
        ['Registration date (oldest first)', 'created_at_asc'],
        ['Country (a-z)', 'country_name_asc']
      ]
  end

  def self.options_for_select
    order('LOWER(title)').map { |e| [e.title, e.id] }
  end

  def self.options_for_select_room_nums
    order('room_nums').map { |e| [e.room_nums, e.room_nums] }.uniq
  end


end
