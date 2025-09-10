# frozen_string_literal: true

namespace :punching_bag do
  desc 'Combine old hit records together to improve performance'
  task(
    :combine,
    %i[by_hour_after by_day_after by_month_after by_year_after] => [:environment]
  ) do |_t, args|
    args.with_defaults(
      by_hour_after: 24,
      by_day_after: 7,
      by_month_after: 1,
      by_year_after: 1
    )

    PunchingBag.combine_punches(args)
  end
end
