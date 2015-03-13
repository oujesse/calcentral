require 'spec_helper'
require 'selenium-webdriver'
require 'page-object'
require 'csv'
require 'json'
require_relative 'util/web_driver_utils'
require_relative 'util/user_utils'
require_relative 'pages/cal_central_pages'
require_relative 'pages/splash_page'
require_relative 'pages/my_academics_class_page'

describe 'My Academics webcasts card', :testui => true do

  if ENV["UI_TEST"]

    include ClassLogger

    begin

      driver = WebDriverUtils.driver

      test_users = UserUtils.load_test_users
      testable_users = []
      test_users.each do |user|
        unless user['webcast'].nil?
          uid = user['uid'].to_s
          logger.info("UID is #{uid}")
          class_page = user['webcast']['classPagePath']
          lecture_count = user['webcast']['lectures']
          you_tube_video_id = user['webcast']['video']
          audio_url = user['webcast']['audio']

          begin
            splash_page = CalCentralPages::SplashPage.new(driver)
            splash_page.load_page(driver)
            splash_page.basic_auth(driver, uid)
            my_academics = CalCentralPages::MyAcademicsClassPage.new(driver)
            my_academics.load_class_page(driver, class_page)
            my_academics.wait_for_webcasts
            testable_users.push(uid)

            if you_tube_video_id.nil? && !audio_url.nil?
              my_academics.audio_source_element.when_present(timeout=WebDriverUtils.academics_timeout)
              has_right_default_tab = my_academics.audio_element.visible?
              it "shows the audio tab by default for UID #{uid}" do
                expect(has_right_default_tab).to be true
              end
              my_academics.video_tab
              has_no_video_message = my_academics.no_video_msg?
              it "shows a 'no video' message for UID #{uid}" do
                expect(has_no_video_message).to be true
              end
            elsif you_tube_video_id.nil? && audio_url.nil?
              has_no_webcast_message = my_academics.no_webcast_msg?
              it "shows a 'no webcasts' message for UID #{uid}" do
                expect(has_no_webcast_message).to be true
              end
            elsif audio_url.nil? && !you_tube_video_id.nil?
              my_academics.video_thumbnail_element.when_present(timeout=WebDriverUtils.academics_timeout)
              has_right_default_tab = my_academics.video_thumbnail_element.visible?
              it "shows the video tab by default for UID #{uid}" do
                expect(has_right_default_tab).to be true
              end
              my_academics.audio_tab
              has_no_audio_message = my_academics.no_audio_msg?
              it "shows a 'no audio' message for UID #{uid}" do
                expect(has_no_audio_message).to be true
              end
            else
              my_academics.video_thumbnail_element.when_present(timeout=WebDriverUtils.academics_timeout)
              has_right_default_tab = my_academics.video_thumbnail_element.visible?
              it "shows the video tab by default for UID #{uid}" do
                expect(has_right_default_tab).to be true
              end
            end

            unless you_tube_video_id.nil?
              my_academics.video_tab_element.when_present(timeout=WebDriverUtils.page_event_timeout)
              my_academics.video_tab
              all_visible_video_lectures = my_academics.video_select_element.options.length
              thumbnail_present = my_academics.video_thumbnail_element.attribute('src').include? you_tube_video_id
              auto_play = my_academics.you_tube_video_auto_plays?(driver)
              it "shows all the available lecture videos for UID #{uid}" do
                expect(all_visible_video_lectures).to eql(lecture_count)
              end
              it "shows the right video thumbnail for UID #{uid}" do
                expect(thumbnail_present).to be true
              end
              it "plays the video automatically when clicked for UID #{uid}" do
                expect(auto_play).to be true
              end
            end

            unless audio_url.nil?
              my_academics.audio_tab_element.when_present(timeout=WebDriverUtils.page_event_timeout)
              my_academics.audio_tab
              all_visible_audio_lectures = my_academics.audio_select_element.options.length
              audio_player_present = my_academics.audio_source_element.attribute('src').include? audio_url
              it "shows all the available lecture audio recordings for UID #{uid}" do
                expect(all_visible_audio_lectures).to eql(lecture_count)
              end
              it "shows the right audio player content for UID #{uid}" do
                expect(audio_player_present).to be true
              end
            end

          rescue => e
            logger.error e.message + "\n" + e.backtrace.join("\n ")
          end
        end
      end
      it 'has a webcast UI for at least one of the test users' do
        expect(testable_users.length).to be > 0
      end
    rescue => e
      logger.error e.message + "\n" + e.backtrace.join("\n ")
    ensure
      logger.info('Quitting the browser')
      driver.quit
    end
  end
end
