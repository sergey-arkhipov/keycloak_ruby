# frozen_string_literal: true

module GlobalConstants
  SEARCH_FORM_PERMITED_PARAMS = [search_form: [:query, :search_by_body, :search_by_range, :column, :direction,
                                               :search_by_subtree, :date_range_form, :user, :project,
                                               { statuses_ids: [], classifier_ids: [] }]].freeze
end
