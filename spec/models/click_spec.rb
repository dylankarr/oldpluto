require 'rails_helper'

RSpec.describe Click, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:link).counter_cache(true) }
end
