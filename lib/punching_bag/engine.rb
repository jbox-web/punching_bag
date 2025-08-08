# frozen_string_literal: true

module PunchingBag
  class Engine < Rails::Engine
    initializer 'punching_bag.initialize' do
      ActiveSupport.on_load(:active_record) do
        extend PunchingBag::Macros

        if defined?(::ActsAsTaggableOn)
          ::ActsAsTaggableOn::Tag.extend(PunchingBag::ActsAsTaggableOn::ClassMethods)
          ::ActsAsTaggableOn::Tag.include(PunchingBag::ActsAsTaggableOn::InstanceMethods)
        end
      end
    end
  end
end
