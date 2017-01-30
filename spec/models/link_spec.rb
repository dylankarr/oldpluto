require 'rails_helper'

RSpec.describe Link, type: :model do
  describe 'sanitizes attributes' do
    it 'sanitizes html entities from the title' do
      link = build :link, title: 'Cats &amp; Dogs'
      link.valid?
      expect(link.title).to eq('Cats & Dogs')
    end

    it 'sanitizes html from the title' do
      link = build :link, title: '<p>Cats and Dogs</p>'
      link.valid?
      expect(link.title).to eq('Cats and Dogs')
    end

    it 'sanitizes html entities from the body' do
      link = build :link, body: 'Cats &amp; Dogs'
      link.valid?
      expect(link.body).to eq('Cats & Dogs')
    end

    it 'sanitizes html from the body' do
      link = build :link, body: '<p>Cats and Dogs</p>'
      link.valid?
      expect(link.body).to eq('Cats and Dogs')
    end
  end
end
