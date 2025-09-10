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

  def self.combine_punches(by_hour_after: 24, by_day_after: 7, by_month_after: 1, by_year_after: 1) # rubocop:disable Metrics/MethodLength
    distinct_method = :distinct
    punchable_types = Punch.unscope(:order).public_send(distinct_method).pluck(:punchable_type)

    punchable_types.each do |punchable_type|
      punchables = punchable_type.constantize.unscoped.find(
        Punch.unscope(:order).public_send(distinct_method).where(punchable_type: punchable_type).pluck(:punchable_id)
      )

      punchables.each do |punchable|
        combine(punchable, scope: by_year_after,  by: :year)
        combine(punchable, scope: by_month_after, by: :month)
        combine(punchable, scope: by_day_after,   by: :day)
        combine(punchable, scope: by_hour_after,  by: :hour)
      end
    end
  end

  def self.combine(punchable, scope:, by:)
    cast_method    = :"#{by}s" # years/months/days/hours
    aggrate_method = :"combine_by_#{by}"

    punchable.punches.before(
      scope.to_i.send(cast_method).ago
    ).each do |punch|
      # Dont use the cached version.
      # We might have changed if we were the combo
      punch.reload
      punch.public_method(aggrate_method)
    end
  end
end
