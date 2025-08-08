# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Punch do
  subject { punch }

  let(:day) { Time.now.utc.beginning_of_day }
  let(:month) { Time.now.utc.beginning_of_month }
  let(:year) { Time.now.utc.beginning_of_year }

  let(:attrs) { {} }
  let(:article) { Article.create title: 'Bluths', content: "I know, I just call her Annabelle cause she's shaped" }
  let(:punch) { described_class.new attrs.merge(punchable: article) }

  before { subject.valid? } # sets default values

  context 'with one hit' do
    its(:hits) { is_expected.to be 1 }
    its(:jab?) { is_expected.to be true }
    its(:combo?) { is_expected.to be false }
  end

  context 'with two hits' do
    let(:attrs) { { hits: 2 } }

    its(:hits) { is_expected.to be 2 }
    its(:jab?) { is_expected.to be false }
    its(:combo?) { is_expected.to be true }
  end

  context 'with start time same as end time' do
    its(:timeframe) { is_expected.to be :second }
    its(:day_combo?) { is_expected.to be false }
    its(:month_combo?) { is_expected.to be false }
    its(:year_combo?) { is_expected.to be false }
  end

  context 'with start time in the same day as end time' do
    let(:attrs) { { starts_at: day + 1.hour, ends_at: day + 2.hours } }

    its(:timeframe) { is_expected.to be :day }
    its(:day_combo?) { is_expected.to be true }
    its(:month_combo?) { is_expected.to be false }
    its(:year_combo?) { is_expected.to be false }
  end

  context 'with start time in the same month as end time' do
    let(:attrs) { { starts_at: month + 1.day, ends_at: month + 2.days } }

    its(:timeframe) { is_expected.to be :month }
    its(:day_combo?) { is_expected.to be false }
    its(:month_combo?) { is_expected.to be true }
    its(:year_combo?) { is_expected.to be false }
  end

  context 'with start time in the same year as end time' do
    let(:attrs) { { starts_at: year + 1.month, ends_at: year + 2.months } }

    its(:timeframe) { is_expected.to be :year }
    its(:day_combo?) { is_expected.to be false }
    its(:month_combo?) { is_expected.to be false }
    its(:year_combo?) { is_expected.to be true }
  end

  context 'with only one punch on a day' do
    let(:other_punch) { nil }

    before { punch.save! }

    describe '#combine_with' do
      it { expect { punch.combine_with other_punch }.to_not change(described_class, :count) }
    end
  end

  context 'with another punch on the same day' do
    let(:attrs) { { hits: 1, starts_at: day + 1.hour } }
    let!(:other_punch) { described_class.create punchable: article, starts_at: day + 2.hours }
    let!(:next_week_punch) { described_class.create punchable: article, starts_at: day + 7.days }

    before { punch.save! }

    describe '#combine_with' do
      it 'destroys the punch' do
        expect { punch.combine_with other_punch }.to change(punch, :destroyed?).from(false).to true
      end

      it 'combines the hits' do
        expect { punch.combine_with other_punch }.to change(other_punch, :hits).from(1).to 2
      end

      it 'changes starts_at or ends_at' do
        expect { punch.combine_with other_punch }.to change(other_punch, :starts_at).from(day + 2.hours).to(day + 1.hour)
      end

      it 'changes the average_time' do
        expect { punch.combine_with other_punch }.to change(other_punch, :average_time).from(day + 2.hours).to(day + 90.minutes)
      end
    end

    describe '#find_combo_for' do
      it 'finds the other punch in the day' do
        expect(punch.find_combo_for(:day)).to eql other_punch
      end

      it "does't find the next week punch" do
        expect(punch.find_combo_for(:day)).to_not eql next_week_punch
      end
    end
  end
end
