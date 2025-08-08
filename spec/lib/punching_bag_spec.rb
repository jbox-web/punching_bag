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
  end
end
