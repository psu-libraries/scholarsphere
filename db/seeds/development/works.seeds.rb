after 'development:users' do
  def has_draft?
    rand > 0.5
  end

  user_list = User.order('RANDOM()').limit(100)

  100.times do
    FactoryBot.create(:work, depositor: user_list.sample, versions_count: rand(1..5), has_draft: has_draft?)
  end
end
