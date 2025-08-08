# frozen_string_literal: true

module PunchingBag
  module Macros
    def acts_as_punchable
      extend PunchingBag::ActiveRecord::ClassMethods
      include PunchingBag::ActiveRecord::InstanceMethods

      has_many :punches, as: :punchable, dependent: :destroy
    end
  end
end
