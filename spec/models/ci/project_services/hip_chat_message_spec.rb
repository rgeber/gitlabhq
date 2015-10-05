require 'spec_helper'

describe Ci::HipChatMessage do
  subject { Ci::HipChatMessage.new(build) }

  context "One build" do
    let(:commit) { FactoryGirl.create(:ci_commit_with_one_job) }

    let(:build) do
      commit.create_builds('master', false, nil)
      commit.builds.first
    end

    context 'when build succeeds' do
      it 'returns a successful message' do
        build.update(status: "success")

        expect( subject.status_color ).to eq 'green'
        expect( subject.notify? ).to be_falsey
        expect( subject.to_s ).to match(/Build '[^']+' #\d+/)
        expect( subject.to_s ).to match(/Successful in \d+ second\(s\)\./)
      end
    end

    context 'when build fails' do
      it 'returns a failure message' do
        build.update(status: "failed")

        expect( subject.status_color ).to eq 'red'
        expect( subject.notify? ).to be_truthy
        expect( subject.to_s ).to match(/Build '[^']+' #\d+/)
        expect( subject.to_s ).to match(/Failed in \d+ second\(s\)\./)
      end
    end
  end

  context "Several builds" do
    let(:commit) { FactoryGirl.create(:ci_commit_with_two_jobs) }

    let(:build) do
      commit.builds.first
    end

    context 'when all matrix builds succeed' do
      it 'returns a successful message' do
        commit.create_builds('master', false, nil)
        commit.builds.update_all(status: "success")
        commit.reload

        expect( subject.status_color ).to eq 'green'
        expect( subject.notify? ).to be_falsey
        expect( subject.to_s ).to match(/Commit #\d+/)
        expect( subject.to_s ).to match(/Successful in \d+ second\(s\)\./)
      end
    end

    context 'when at least one matrix build fails' do
      it 'returns a failure message' do
        commit.create_builds('master', false, nil)
        first_build = commit.builds.first
        second_build = commit.builds.last
        first_build.update(status: "success")
        second_build.update(status: "failed")

        expect( subject.status_color ).to eq 'red'
        expect( subject.notify? ).to be_truthy
        expect( subject.to_s ).to match(/Commit #\d+/)
        expect( subject.to_s ).to match(/Failed in \d+ second\(s\)\./)
      end
    end
  end
end
