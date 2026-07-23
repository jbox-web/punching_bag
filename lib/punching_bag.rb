# frozen_string_literal: true

# require ruby dependencies
require 'logger'

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

  # Records a punch on `punchable`. When a `request` is passed and it reports
  # `bot?` truthy (via voight_kampff), nothing is recorded and false is returned.
  # Passing no request skips the bot check entirely, so bots are counted.
  # Returns the saved Punch, or false when skipped or the save fails.
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
    raise ArgumentError, 'cannot average a zero total of hits' if hits.zero?

    Time.zone.at(total_time / hits)
  end

  def self.logger
    @logger ||= Logger.new($stdout)
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.combine_punches(by_hour_after: 24, by_day_after: 7, by_month_after: 1, by_year_after: 1) # rubocop:disable Metrics/MethodLength
    punchable_types = Punch.unscope(:order).distinct.pluck(:punchable_type)

    punchable_types.each do |punchable_type|
      # Skip a type whose model was renamed/removed instead of aborting the whole run.
      klass = punchable_type.safe_constantize
      next unless klass

      ids = Punch.unscope(:order).distinct.where(punchable_type: punchable_type).pluck(:punchable_id)

      # find_each batches the load (bounded memory) and where(id:) silently drops
      # orphaned punches whose punchable was already deleted.
      klass.unscoped.where(id: ids).find_each do |punchable|
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

    logger.debug { "Combining punches: by_#{by} / #{punchable.class.name}##{punchable.id}" }

    punchable.punches.before(
      scope.to_i.public_send(cast_method).ago
    ).find_each do |punch|
      # Dont use the cached version.
      # We might have changed if we were the combo
      punch.reload
      punch.public_send(aggrate_method)
    end
  end
end
