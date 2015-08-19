# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#

require 'spec_helper'

describe JenkinsService do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'commits methods' do
    def status_body_for_icon(state)
      body =<<eos
        <h1 class="build-caption page-headline"><img style="width: 48px; height: 48px; " alt="Success" class="icon-#{state} icon-xlg" src="/static/855d7c3c/images/48x48/#{state}" tooltip="Success" title="Success">
                Build #188
              (Oct 15, 2014 9:45:21 PM)
                    </h1>
eos
    end

    before do
      @service = JenkinsService.new
      allow(@service).to receive_messages(
        service_hook: true,
        project_url: 'http://jenkins.gitlab.org/projects/2',
        token: 'verySecret'
      )
    end

    describe :commit_status do
      statuses = {'blue.png' => 'success', 'yellow.png' => 'failed', 'red.png' => 'failed', 'aborted.png' => 'failed', 'blue-anime.gif' => 'running', 'grey.png' => 'pending'}
      statuses.each do |icon, state|
        it "should have a status of #{state} when the icon #{icon} exists." do
          stub_request(:get, "http://jenkins.gitlab.org/projects/2/scm/bySHA1/2ab7834c").to_return(status: 200, body: status_body_for_icon(icon), headers: {})
          expect(@service.commit_status("2ab7834c", 'master')).to eq(state)
        end
      end
    end

    describe :build_page do
      it { expect(@service.build_page("2ab7834c", 'master')).to eq("http://jenkins.gitlab.org/projects/2/scm/bySHA1/2ab7834c") }
    end

    describe :build_page_with_branch do
      it { expect(@service.build_page("2ab7834c", 'test_branch')).to eq("http://jenkins.gitlab.org/projects/2_test_branch/scm/bySHA1/2ab7834c") }
    end
  end
end
