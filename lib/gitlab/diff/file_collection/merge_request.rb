module Gitlab
  module Diff
    module FileCollection
      class MergeRequest < Base
        def initialize(merge_request, diff_options:)
          @merge_request = merge_request

          super(merge_request,
            project: merge_request.project,
            diff_options: diff_options,
            diff_refs: merge_request.diff_refs)
        end

        def diff_files
          super.tap { |_| store_highlight_cache }
        end

        private

        # Extracted method to highlight in the same iteration to the diff_collection.
        def decorate_diff!(diff)
          diff_file = super
          cache_highlight!(diff_file) if cacheable?
          diff_file
        end

        def highlight_diff_file_from_cache!(diff_file, cache_diff_lines)
          diff_file.highlighted_diff_lines = cache_diff_lines.map do |line|
            Gitlab::Diff::Line.init_from_hash(line)
          end
        end

        #
        # If we find the highlighted diff files lines on the cache we replace existing diff_files lines (no highlighted)
        # for the highlighted ones, so we just skip their execution.
        # If the highlighted diff files lines are not cached we calculate and cache them.
        #
        # The content of the cache is a Hash where the key correspond to the file_path and the values are Arrays of
        # hashes that represent serialized diff lines.
        #
        def cache_highlight!(diff_file)
          file_path = diff_file.file_path

          if highlight_cache[file_path]
            highlight_diff_file_from_cache!(diff_file, highlight_cache[file_path])
          else
            highlight_cache[file_path] = diff_file.highlighted_diff_lines.map(&:to_hash)
          end
        end

        def highlight_cache
          return @highlight_cache if defined?(@highlight_cache)

          @highlight_cache = Rails.cache.read(cache_key) || {}
          @highlight_cache_was_empty = @highlight_cache.empty?
          @highlight_cache
        end

        def store_highlight_cache
          Rails.cache.write(cache_key, highlight_cache) if @highlight_cache_was_empty
        end

        def cacheable?
          @merge_request.merge_request_diff.present?
        end

        def cache_key
          [@merge_request.merge_request_diff, 'highlighted-diff-files', diff_options]
        end
      end
    end
  end
end
