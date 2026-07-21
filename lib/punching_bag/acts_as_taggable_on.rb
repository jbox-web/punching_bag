# frozen_string_literal: true

# Adds methods to enable tracking tags through a common polymorphic association
module PunchingBag
  module ActsAsTaggableOn
    # Join taggings to the punches recorded on their taggable records.
    PUNCHES_JOIN = 'INNER JOIN punches ON (taggings.taggable_id = punches.punchable_id ' \
                   'AND taggings.taggable_type = punches.punchable_type)'

    module ClassMethods
      def most_hit(since = nil, limit = 5)
        # NOTE: use the fully-qualified ::ActsAsTaggableOn::Tagging; a bare
        # `Tagging` does not resolve from this namespace. `.scoped` was removed
        # in Rails 4.1, so start the relation from the class directly.
        query = ::ActsAsTaggableOn::Tagging
                  .joins(PUNCHES_JOIN)
                  .group(:tag_id)
                  .order(Arel.sql('SUM(punches.hits) DESC'))
                  .limit(limit)
        query = query.where('punches.average_time >= ?', since) if since

        # pluck the grouped tag_ids (already ordered by hit count), then reload
        # the tags preserving that order — avoids a SELECT * under GROUP BY.
        tag_ids = query.pluck(:tag_id)
        tags = ::ActsAsTaggableOn::Tag.where(id: tag_ids).index_by(&:id)
        tag_ids.filter_map { |tag_id| tags[tag_id] }
      end
    end

    module InstanceMethods
      def hits(since = nil)
        query = ::ActsAsTaggableOn::Tagging.joins(PUNCHES_JOIN).where(tag_id: id)
        query = query.where('punches.average_time >= ?', since) if since
        query.sum('punches.hits')
      end
    end
  end
end
