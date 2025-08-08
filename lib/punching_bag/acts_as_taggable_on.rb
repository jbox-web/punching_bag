# frozen_string_literal: true

# Adds methods to enable tracking tags through a common polymorphic association
module PunchingBag
  module ActsAsTaggableOn
    module ClassMethods
      def most_hit(since = nil, limit = 5)
        query = Tagging.scoped
                  .joins('INNER JOIN punches ON (taggings.taggable_id = punches.punchable_id AND taggings.taggable_type = punches.punchable_type)')
                  .group(:tag_id)
                  .order('SUM(punches.hits) DESC')
                  .limit(limit)
        query = query.where('punches.average_time >= ?', since) if since
        query.map(&:tag)
      end
    end

    module InstanceMethods
      def hits(since = nil)
        query = Tagging.scoped
                  .joins('INNER JOIN punches ON (taggings.taggable_id = punches.punchable_id AND taggings.taggable_type = punches.punchable_type)')
                  .where(tag_id: id)
        query = query.where('punches.average_time >= ?', since) if since
        query.sum('punches.hits')
      end
    end
  end
end
