# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PunchingBag::ActsAsTaggableOn' do
  let(:tag_class) { ActsAsTaggableOn::Tag }

  let(:popular) { Article.create! title: 'Popular', content: 'x', tag_list: 'trending' }
  let(:quiet)   { Article.create! title: 'Quiet',   content: 'x', tag_list: 'niche' }

  before do
    3.times { popular.punch }
    quiet.punch
  end

  describe '.most_hit' do
    it 'orders tags by the summed hits of their taggables' do
      expect(tag_class.most_hit.map(&:name)).to eq(%w[trending niche])
    end

    it 'honours the limit' do
      expect(tag_class.most_hit(nil, 1).map(&:name)).to eq(%w[trending])
    end

    it 'filters out punches older than the given time' do
      expect(tag_class.most_hit(1.hour.from_now)).to be_empty
    end
  end

  describe '#hits' do
    it 'sums the hits of the tagged, punched records' do
      trending = tag_class.find_by(name: 'trending')
      expect(trending.hits).to eq 3
    end

    it 'filters out punches older than the given time' do
      trending = tag_class.find_by(name: 'trending')
      expect(trending.hits(1.hour.from_now)).to eq 0
    end
  end
end
