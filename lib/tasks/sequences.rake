# frozen_string_literal: true

namespace :db do
  namespace :update do
    desc "Creating new sequences for existing projects"
    task article_code_sequences: :environment do
      # Запоминаем последнее значение единой последовательности article_code_sequence
      start_val = Sequences::ArticleCodeId.next("article_code_sequence")

      Project.find_each do |project|
        project.send(:create_sequence_for_article_codes, start_val)
        project.save

        Rails.logger.info("Created sequence name: #{project.sequence_code_name} and save this to project #{project.id}: #{project.name}") # rubocop:disable Layout/LineLength
      end
    end
  end
end
