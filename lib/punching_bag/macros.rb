# frozen_string_literal: true

module PunchingBag
  module Macros
    # The gem's entry point: call this in a host model to make it trackable.
    # It declares the polymorphic `has_many :punches` association and mixes in
    # the class methods (most_hit, sort_by_popularity) and instance methods
    # (hits, punch). Macros is extended onto ActiveRecord::Base by the engine.
    def acts_as_punchable
      extend PunchingBag::ActiveRecord::ClassMethods
      include PunchingBag::ActiveRecord::InstanceMethods

      has_many :punches, as: :punchable, dependent: :destroy
    end
  end
end
