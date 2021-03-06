# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'json'

module UscisQuizScraper
  class Scraper
    BASE_URL = 'https://www.uscis.gov'
    QUESTIONS_URL = File.join(
      BASE_URL,
      'citizenship',
      'teachers',
      'educational-products',
      '100-civics-questions-and-answers-mp3-audio-english-version'
    )

    def page
      @page ||= Nokogiri::HTML(URI.open(QUESTIONS_URL))
    end

    def question_paragraphs
      @question_paragraphs ||= page.css('.field-item.even p>strong').select { |p| p.text[0] =~ /\A\d+/ }
    end

    def questions
      @questions ||= question_paragraphs.map do |p|
        # Strip whitespaces and question id prefix like "33. "
        p.text.split('Question').first.sub(/\A\d*\./, '').strip
      end
    end

    def audio_links
      @audio_links ||= question_paragraphs.map { |p| File.join(BASE_URL, p.css('a').first[:href]) }
    end

    def answers
      @answers ||= page.css('.field-item.even ul').map do |p|
        p.css('li div').map { |div| div.text&.strip }
      end.reject(&:empty?)
    end

    def hash
      (0..99).map do |i|
        {
          id: i + 1,
          question: questions[i],
          answer: answers[i],
          audio_link: audio_links[i]
        }
      end
    end

    def json
      hash.to_json
    end
  end
end
