require "rails_helper"

RSpec.feature "Saying hello", :type => :feature do
  scenario "User visits the root page" do
    visit "/"

    expect(page).to have_text("Hello from test!")
  end
end
