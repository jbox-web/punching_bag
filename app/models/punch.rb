# frozen_string_literal: true

class Punch < ActiveRecord::Base
  belongs_to :punchable, polymorphic: true

  before_validation :set_defaults
  validates :punchable_id, :punchable_type, :starts_at, :ends_at, :average_time, :hits, presence: true

  # NOTE: prefer this explicit scope over a default_scope: a default order
  # silently applies to every query and forces callers to unscope/reorder it.
  scope :by_average_time, -> { order(average_time: :desc) }
  scope :combos, -> { where 'punches.hits > 1' }
  scope :jabs, -> { where hits: 1 }
  scope :before, ->(time = nil) { where('punches.ends_at <= ?', time) unless time.nil? }
  scope :after, ->(time = nil) { where('punches.average_time >= ?', time) unless time.nil? }
  scope :by_timeframe, ->(timeframe, time) {
    where('punches.starts_at >= ? AND punches.ends_at <= ?', time.send("beginning_of_#{timeframe}"), time.send("end_of_#{timeframe}"))
  }
  scope :by_hour, ->(hour) { by_timeframe :hour, hour }
  scope :by_day, ->(day) { by_timeframe :day, day }
  scope :by_month, ->(month) { by_timeframe :month, month }
  scope :by_year, ->(year) {
    year = DateTime.new(year) if year.is_a? Integer
    by_timeframe :year, year
  }
  scope :except_for, ->(punch) { where('id != ?', punch.id) }

  class << self
    def average_for(punchables) # rubocop:disable Metrics/AbcSize
      raise ArgumentError, 'Punchables must all be of the same class' if punchables.map(&:class).uniq.length > 1

      sums = Punch.where(punchable_type: punchables.first.class.to_s, punchable_id: punchables.map(&:id)).group(:punchable_id).sum(:hits)

      return 0 if sums.empty? # catch divide by zero

      sums.values.sum.to_f / sums.length
    end
  end

  def jab?
    hits == 1
  end

  def combo?
    hits > 1
  end

  # NOTE: compare the enclosing period (beginning_of_month/day/hour), not the
  # bare month/day/hour numbers: two timestamps a year apart can share the same
  # month/day/hour number yet belong to different periods.
  def timeframe # rubocop:disable Metrics/MethodLength
    if starts_at.beginning_of_month != ends_at.beginning_of_month
      :year
    elsif starts_at.beginning_of_day != ends_at.beginning_of_day
      :month
    elsif starts_at.beginning_of_hour != ends_at.beginning_of_hour
      :day
    elsif starts_at != ends_at
      :hour
    else
      :second
    end
  end

  def hour_combo?
    timeframe == :hour and find_true_combo_for(:hour) != self
  end

  def day_combo?
    timeframe == :day and find_true_combo_for(:day) != self
  end

  def month_combo?
    timeframe == :month and find_true_combo_for(:month) != self
  end

  def year_combo?
    timeframe == :year and find_true_combo_for(:year) != self
  end

  def find_combo_for(timeframe)
    punches = punchable.punches.by_timeframe(timeframe, average_time).except_for(self).by_average_time
    punches.combos.first || punches.first
  end

  def find_true_combo_for(timeframe)
    punchable.punches.combos.by_timeframe(timeframe, average_time).by_average_time.first
  end

  def combine_with(combo) # rubocop:disable Metrics/AbcSize
    return combo unless combo && combo != self

    combo.starts_at = starts_at if starts_at < combo.starts_at
    combo.ends_at = ends_at if ends_at > combo.ends_at
    combo.average_time = PunchingBag.average_time(combo, self)
    combo.hits += hits
    # Atomic: a crash between saving the combo and destroying self would otherwise double-count the hits.
    transaction { destroy if combo.save }
    combo
  end

  def combine_by_hour
    return if hour_combo? || day_combo? || month_combo? || year_combo?

    combine_with find_combo_for(:hour)
  end

  def combine_by_day
    return if day_combo? || month_combo? || year_combo?

    combine_with find_combo_for(:day)
  end

  def combine_by_month
    return if month_combo? || year_combo?

    combine_with find_combo_for(:month)
  end

  def combine_by_year
    return if year_combo?

    combine_with find_combo_for(:year)
  end

  private

  def set_defaults
    if (date = (self.starts_at ||= Time.current))
      self.ends_at ||= date
      self.average_time ||= date
      self.hits ||= 1
    end
  end
end
