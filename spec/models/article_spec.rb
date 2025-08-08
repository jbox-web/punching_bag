# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Article do
  let(:article1) { described_class.create title: 'Bacon', content: 'Bacon ipsum dolor sit amet turkey short ribs tri-tip' }
  let(:article2) { described_class.create title: 'Hipsters', content: 'American Apparel aute Banksy officia ugh.' }
  let(:article3) { described_class.create title: 'Lebowski', content: 'Lebowski ipsum over the line!' }

  # Instance methods
  describe 'instance methods' do
    subject { article1 }

    describe '#hits' do
      context 'with no hits' do
        its(:hits) { is_expected.to be 0 }
      end

      context 'with one hit' do
        before { subject.punch }

        its(:hits) { is_expected.to be 1 }
      end
    end

    describe '#punch' do
      it 'incleases hits by one' do
        expect { subject.punch }.to change(subject, :hits).by 1
      end

      context 'when count is set to two' do
        it 'increases hits by two' do
          expect { subject.punch(nil, count: 2) }.to change(subject, :hits).by 2
        end
      end
    end
  end

  # Class methods
  describe 'class methods' do
    subject { described_class }

    before do
      2.times { article3.punch }
      article1.punch
    end

    describe '.most_hit' do
      its(:most_hit) { is_expected.to include article3 }
      its(:most_hit) { is_expected.to include article1 }
      its(:most_hit) { is_expected.to_not include article2 }

      its('most_hit.first') { is_expected.to eql article3 }
      its('most_hit.second') { is_expected.to eql article1 }
    end

    describe '.sort_by_popularity' do
      its(:sort_by_popularity) { is_expected.to include article1 }
      its(:sort_by_popularity) { is_expected.to include article2 }
      its(:sort_by_popularity) { is_expected.to include article3 }

      its('sort_by_popularity.first') { is_expected.to eql article3 }
      its('sort_by_popularity.second') { is_expected.to eql article1 }
    end
  end
end
