require "nokogiri"
require "open-uri"
require "json"

module UscisQuestions
  class Scraper
    SITE_URL = "https://www.uscis.gov/citizenship/teachers/educational-products/100-civics-questions-and-answers-mp3-audio-english-version"

    def page
      @page ||= Nokogiri::HTML(open(SITE_URL))
    end

    def question_paragraphs
      @question_paragraphs ||= page.css(".field-item.even p>strong").select { |p| p.text[0] =~ /\A\d+/ }
    end

    def questions
      @questions ||= question_paragraphs.map { |p| p.text.split("Question").first }
    end

    def audio_links
      @audio_links ||= question_paragraphs.map { |p| p.css("a").first[:href] }
    end

    def answers
      @answers ||= page.css(".field-item.even ul").map { |p|
        p.css("li div").map {|div| div.text }
      }.select { |list| list.size > 0 }
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