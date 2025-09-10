# frozen_string_literal: true

# require external dependencies
require 'zeitwerk'
require 'voight_kampff'

# load zeitwerk
Zeitwerk::Loader.for_gem.tap do |loader|
  loader.ignore("#{__dir__}/generators")
  loader.setup
end

module PunchingBag
  require_relative 'punching_bag/engine' if defined?(Rails)

  def self.punch(punchable, request = nil, count = 1)
    if request.try(:bot?)
      false
    else
      p = Punch.new
      p.punchable = punchable
      p.hits = count
      p.save ? p : false
    end
  end

  def self.average_time(*punches)
    total_time = 0
    hits = 0
    punches.each do |punch|
      total_time += punch.average_time.to_f * punch.hits
      hits += punch.hits
    end
    Time.zone.at(total_time / hits)
  end

  def self.combine_punches(args)
    distinct_method = Rails.version >= '5.0' ? :distinct : :uniq

    punchable_types = Punch.unscope(:order).public_send(
      distinct_method
    ).pluck(:punchable_type)

    punchable_types.each do |punchable_type|
      punchables = punchable_type.constantize.unscoped.find(
        Punch.unscope(:order).public_send(distinct_method).where(
          punchable_type: punchable_type
        ).pluck(:punchable_id)
      )

      punchables.each do |punchable|
        # by_year
        punchable.punches.before(
          args[:by_year_after].to_i.years.ago
        ).each do |punch|
          # Dont use the cached version.
          # We might have changed if we were the combo
          punch.reload
          punch.combine_by_year
        end

        # by_month
        punchable.punches.before(
          args[:by_month_after].to_i.months.ago
        ).each do |punch|
          # Dont use the cached version.
          # We might have changed if we were the combo
          punch.reload
          punch.combine_by_month
        end

        # by_day
        punchable.punches.before(
          args[:by_day_after].to_i.days.ago
        ).each do |punch|
          # Dont use the cached version.
          # We might have changed if we were the combo
          punch.reload
          punch.combine_by_day
        end

        # by_hour
        punchable.punches.before(
          args[:by_hour_after].to_i.hours.ago
        ).each do |punch|
          # Dont use the cached version.
          # We might have changed if we were the combo
          punch.reload
          punch.combine_by_hour
        end
      end
    end
  end
end
