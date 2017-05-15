require 'rails_helper'

RSpec.describe TopicTimer, type: :model do
  let(:topic_timer) { Fabricate(:topic_timer) }
  let(:topic) { Fabricate(:topic) }

  before do
    Jobs::ToggleTopicClosed.jobs.clear
  end

  context "validations" do
    describe '#status_type' do
      it 'should ensure that only one active topic status update exists' do
        topic_timer.update!(topic: topic)
        Fabricate(:topic_timer, deleted_at: Time.zone.now, topic: topic)

        expect { Fabricate(:topic_timer, topic: topic) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    describe '#execute_at' do
      describe 'when #execute_at is greater than #created_at' do
        it 'should be valid' do
          topic_timer = Fabricate.build(:topic_timer,
            execute_at: Time.zone.now + 1.hour,
            user: Fabricate(:user),
            topic: Fabricate(:topic)
          )

          expect(topic_timer).to be_valid
        end
      end

      describe 'when #execute_at is smaller than #created_at' do
        it 'should not be valid' do
          topic_timer = Fabricate.build(:topic_timer,
            execute_at: Time.zone.now - 1.hour,
            created_at: Time.zone.now,
            user: Fabricate(:user),
            topic: Fabricate(:topic)
          )

          expect(topic_timer).to_not be_valid
        end
      end
    end

    describe '#category_id' do
      describe 'when #status_type is publish_to_category' do
        describe 'when #category_id is not present' do
          it 'should not be valid' do
            topic_timer = Fabricate.build(:topic_timer,
              status_type: TopicTimer.types[:publish_to_category]
            )

            expect(topic_timer).to_not be_valid
            expect(topic_timer.errors.keys).to include(:category_id)
          end
        end

        describe 'when #category_id is present' do
          it 'should be valid' do
            topic_timer = Fabricate.build(:topic_timer,
              status_type: TopicTimer.types[:publish_to_category],
              category_id: Fabricate(:category).id,
              user: Fabricate(:user),
              topic: Fabricate(:topic)
            )

            expect(topic_timer).to be_valid
          end
        end
      end
    end
  end

  context 'callbacks' do
    describe 'when #execute_at and #user_id are not changed' do
      it 'should not schedule another to update topic' do
        Jobs.expects(:enqueue_at).with(
          topic_timer.execute_at,
          :toggle_topic_closed,
          topic_timer_id: topic_timer.id,
          state: true
        ).once

        topic_timer

        Jobs.expects(:cancel_scheduled_job).never

        topic_timer.update!(topic: Fabricate(:topic))
      end
    end

    describe 'when #execute_at value is changed' do
      it 'reschedules the job' do
        Timecop.freeze do
          topic_timer

          Jobs.expects(:cancel_scheduled_job).with(
            :toggle_topic_closed, topic_timer_id: topic_timer.id
          )

          Jobs.expects(:enqueue_at).with(
            3.days.from_now, :toggle_topic_closed,
            topic_timer_id: topic_timer.id,
            state: true
          )

          topic_timer.update!(execute_at: 3.days.from_now, created_at: Time.zone.now)
        end
      end

      describe 'when execute_at is smaller than the current time' do
        it 'should enqueue the job immediately' do
          Timecop.freeze do
            topic_timer

            Jobs.expects(:enqueue_at).with(
              Time.zone.now, :toggle_topic_closed,
              topic_timer_id: topic_timer.id,
              state: true
            )

            topic_timer.update!(
              execute_at: Time.zone.now - 1.hour,
              created_at: Time.zone.now - 2.hour
            )
          end
        end
      end
    end

    describe 'when user is changed' do
      it 'should update the job' do
        Timecop.freeze do
          topic_timer

          Jobs.expects(:cancel_scheduled_job).with(
            :toggle_topic_closed, topic_timer_id: topic_timer.id
          )

          admin = Fabricate(:admin)

          Jobs.expects(:enqueue_at).with(
            topic_timer.execute_at,
            :toggle_topic_closed,
            topic_timer_id: topic_timer.id,
            state: true
          )

          topic_timer.update!(user: admin)
        end
      end
    end

    describe 'when a open topic status update is created for an open topic' do
      let(:topic) { Fabricate(:topic, closed: false) }

      let(:topic_timer) do
        Fabricate(:topic_timer,
          status_type: described_class.types[:open],
          topic: topic
        )
      end

      it 'should close the topic' do
        topic_timer
        expect(topic.reload.closed).to eq(true)
      end

      describe 'when topic has been deleted' do
        it 'should not queue the job' do
          topic.trash!
          topic_timer

          expect(Jobs::ToggleTopicClosed.jobs).to eq([])
        end
      end
    end

    describe 'when a close topic status update is created for a closed topic' do
      let(:topic) { Fabricate(:topic, closed: true) }

      let(:topic_timer) do
        Fabricate(:topic_timer,
          status_type: described_class.types[:close],
          topic: topic
        )
      end

      it 'should open the topic' do
        topic_timer
        expect(topic.reload.closed).to eq(false)
      end

      describe 'when topic has been deleted' do
        it 'should not queue the job' do
          topic.trash!
          topic_timer

          expect(Jobs::ToggleTopicClosed.jobs).to eq([])
        end
      end
    end
  end

  describe '.ensure_consistency!' do
    before do
      SiteSetting.queue_jobs = true
      Jobs::ToggleTopicClosed.jobs.clear
    end

    it 'should enqueue jobs that have been missed' do
      close_topic_timer = Fabricate(:topic_timer,
        execute_at: Time.zone.now - 1.hour,
        created_at: Time.zone.now - 2.hour
      )

      open_topic_timer = Fabricate(:topic_timer,
        status_type: described_class.types[:open],
        execute_at: Time.zone.now - 1.hour,
        created_at: Time.zone.now - 2.hour
      )

      Fabricate(:topic_timer)

      Fabricate(:topic_timer,
        execute_at: Time.zone.now - 1.hour,
        created_at: Time.zone.now - 2.hour
      ).topic.trash!

      expect { described_class.ensure_consistency! }
        .to change { Jobs::ToggleTopicClosed.jobs.count }.by(2)

      job_args = Jobs::ToggleTopicClosed.jobs.first["args"].first

      expect(job_args["topic_timer_id"]).to eq(close_topic_timer.id)
      expect(job_args["state"]).to eq(true)

      job_args = Jobs::ToggleTopicClosed.jobs.last["args"].first

      expect(job_args["topic_timer_id"]).to eq(open_topic_timer.id)
      expect(job_args["state"]).to eq(false)
    end
  end
end
