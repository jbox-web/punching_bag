# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PunchingBag do
  subject { described_class }

  let(:article) { Article.create title: 'Hector', content: 'Ding, ding ding... ding. Ding. DING. DING! ' }

  describe '.punch' do
    let(:request) { nil }

    context 'when request is from a bot' do
      let(:request) { double(ActionDispatch::Request, bot?: true) }

      it 'does nothing' do
        expect(described_class.punch(article, request)).to be false
      end
    end

    context 'when the request is valid' do
      let(:request) { double(ActionDispatch::Request, bot?: false) }

      it 'creates a new punch' do
        expect { described_class.punch(article, request) }.to change(Punch, :count).by 1
      end
    end

    context 'when there is no request' do
      it 'creates a new punch' do
        expect { described_class.punch(article) }.to change(Punch, :count).by 1
      end
    end

    context 'when count is more than one' do
      it 'creates a new punch with a higher count' do
        expect { described_class.punch(article, nil, 2) }.to change { Punch.sum(:hits) }.by 2
      end
    end
  end

  describe '.average_time' do
    let(:time) { Time.zone.now.beginning_of_day }
    let(:punch1) { Punch.new(average_time: time + 15.seconds, hits: 2) }
    let(:punch2) { Punch.new(average_time: time + 30.seconds, hits: 4) }

    it 'finds an average time for multiple punches' do
      expect(described_class.average_time(punch1, punch2)).to eql(time + 25.seconds)
    end

    it 'raises when there are no hits to average' do
      expect { described_class.average_time }.to raise_error(ArgumentError)
    end
  end

  describe '.combine_punches' do
    let(:article) { Article.create title: 'Combo', content: 'ding ding ding' }

    # Old enough to fall past the default by_day_after: 7 threshold.
    let(:old_day) { 10.days.ago.utc.beginning_of_day }

    def create_punch(starts_at)
      Punch.create!(punchable: article, starts_at: starts_at)
    end

    context 'with several separate punches on the same old day' do
      before do
        3.times { |i| create_punch(old_day + i.hours) }
      end

      it 'collapses them into a single combo' do
        expect { described_class.combine_punches }.to change { article.punches.count }.from(3).to(1)
      end

      it 'preserves the total hit count' do
        described_class.combine_punches
        expect(article.hits).to eq 3
      end
    end

    context 'when a punch references a model class that no longer exists' do
      before do
        create_punch(old_day)
        Punch.create!(punchable_type: 'NoSuchModel', punchable_id: 1, starts_at: old_day)
      end

      it 'skips the unknown type instead of raising' do
        expect { described_class.combine_punches }.to_not raise_error
      end
    end

    context 'when a punch is orphaned (its punchable was deleted)' do
      before do
        create_punch(old_day)
        Punch.create!(punchable_type: 'Article', punchable_id: 999_999, starts_at: old_day)
      end

      it 'skips the orphan instead of raising' do
        expect { described_class.combine_punches }.to_not raise_error
      end
    end
  end
end
