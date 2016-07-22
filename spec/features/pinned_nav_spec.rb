require 'spec_helper'

feature 'Pinned nav', feature: true, js: true do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  it 'user can pin nav' do
    show_nav
  end

  it 'hides pinned nav on resize' do
    show_nav

    page.driver.resize_window(1000, 768)

    expect(page).not_to have_selector('.page-sidebar-pinned')
  end

  it 'shows pinned nav after resize' do
    show_nav

    page.driver.resize_window(1000, 768)

    expect(page).not_to have_selector('.page-sidebar-pinned')

    page.driver.resize_window(1024, 768)

    expect(page).to have_selector('.page-sidebar-pinned')
  end

  def show_nav
    find('.side-nav-toggle').click
    find('.js-nav-pin').click

    expect(page).to have_selector('.page-sidebar-pinned')
  end
end
