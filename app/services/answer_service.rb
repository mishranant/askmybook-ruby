require 'csv'
require 'openai'
require 'matrix'
class AnswerService

  COMPLETIONS_MODEL = 'gpt-3.5-turbo-instruct'.freeze
  EMBEDDINGS_MODEL = 'text-embedding-ada-002'.freeze
  MAX_SECTION_LEN = 500
  SEPARATOR = "\n* ".freeze

  def initialize(question_text)
    @question_text = question_text
    @client = OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY'))
  end

  def getAnswer
    pages = CSV.read('book.pdf.pages.csv', headers: true)
    embeddings = load_embeddings('book.pdf.embeddings.csv')

    prompt, context = construct_prompt(
      @question_text,
      embeddings,
      pages
    )

    puts '===\n', prompt

    response = @client.completions(
      parameters: {
        prompt:,
        temperature: 0.0,
        max_tokens: 150,
        model: COMPLETIONS_MODEL
      }
    )
    answer = response.dig('choices', 0, 'text')

    { answer:, context: }
  end

  private

  def load_embeddings(fname)
    embed_csv = CSV.read(fname, headers: true)
    max_dim = embed_csv.headers
                       .reject { |header| header == 'title' }
                       .map(&:to_i)
                       .max

    embed_csv.each_with_object({}) do |row, hash|
      hash[row['title']] = (0..max_dim).map { |i| row[i.to_s] }
    end
  end

  def construct_prompt(question, embeddings, pages)
    most_relevant_document_sections = order_document_sections_by_query_similarity(question, embeddings)

    chosen_sections = []
    chosen_sections_len = 0
    chosen_sections_indexes = []

    most_relevant_document_sections.each do |_, section_index|
      document_section = pages.find { |row| row['title'] == section_index }

      chosen_sections_len += document_section['tokens'].to_i + SEPARATOR.length
      if chosen_sections_len > MAX_SECTION_LEN
        space_left = MAX_SECTION_LEN - chosen_sections_len + document_section['tokens'].to_i
        chosen_sections.append(SEPARATOR + document_section['content'].slice(0, space_left))
        chosen_sections_indexes.append(section_index)
        break
      end

      chosen_sections.append(SEPARATOR + document_section['content'])
      chosen_sections_indexes.append(section_index)
    end

    header = "Sahil Lavingia is the founder and CEO of Gumroad, and the author of the book The Minimalist Entrepreneur (also known as TME). These are questions and answers by him. Please keep your answers to three sentences maximum, and speak in complete sentences. Stop speaking once your point is made.\n\nContext that may be useful, pulled from The Minimalist Entrepreneur:\n"

    question1 = "\n\n\nQ: How to choose what business to start?\n\nA: First off don't be in a rush. Look around you, see what problems you or other people are facing, and solve one of these problems if you see some overlap with your passions or skills. Or, even if you don't see an overlap, imagine how you would solve that problem anyway. Start super, super small."
    question2 = "\n\n\nQ: Q: Should we start the business on the side first or should we put full effort right from the start?\n\nA:   Always on the side. Things start small and get bigger from there, and I don't know if I would ever “fully” commit to something unless I had some semblance of customer traction. Like with this product I'm working on now!"
    question3 = "\n\n\nQ: Should we sell first than build or the other way around?\n\nA: I would recommend building first. Building will teach you a lot, and too many people use “sales” as an excuse to never learn essential skills like building. You can't sell a house you can't build!"
    question4 = "\n\n\nQ: Andrew Chen has a book on this so maybe touché, but how should founders think about the cold start problem? Businesses are hard to start, and even harder to sustain but the latter is somewhat defined and structured, whereas the former is the vast unknown. Not sure if it's worthy, but this is something I have personally struggled with\n\nA: Hey, this is about my book, not his! I would solve the problem from a single player perspective first. For example, Gumroad is useful to a creator looking to sell something even if no one is currently using the platform. Usage helps, but it's not necessary."
    question5 = "\n\n\nQ: What is one business that you think is ripe for a minimalist Entrepreneur innovation that isn't currently being pursued by your community?\n\nA: I would move to a place outside of a big city and watch how broken, slow, and non-automated most things are. And of course the big categories like housing, transportation, toys, healthcare, supply chain, food, and more, are constantly being upturned. Go to an industry conference and it's all they talk about! Any industry…"
    question6 = "\n\n\nQ: How can you tell if your pricing is right? If you are leaving money on the table\n\nA: I would work backwards from the kind of success you want, how many customers you think you can reasonably get to within a few years, and then reverse engineer how much it should be priced to make that work."
    question7 = "\n\n\nQ: Why is the name of your book 'the minimalist entrepreneur' \n\nA: I think more people should start businesses, and was hoping that making it feel more “minimal” would make it feel more achievable and lead more people to starting-the hardest step."
    question8 = "\n\n\nQ: How long it takes to write TME\n\nA: About 500 hours over the course of a year or two, including book proposal and outline."
    question9 = "\n\n\nQ: What is the best way to distribute surveys to test my product idea\n\nA: I use Google Forms and my email list / Twitter account. Works great and is 100% free."
    question10 = "\n\n\nQ: How do you know, when to quit\n\nA: When I'm bored, no longer learning, not earning enough, getting physically unhealthy, etc… loads of reasons. I think the default should be to “quit” and work on something new. Few things are worth holding your attention for a long period of time."

    prompt = header + chosen_sections.join + question1 + question2 + question3 + question4 + question5 + question6 + question7 + question8 + question9 + question10 + "\n\n\nQ: #{question}\n\nA: "
    context = chosen_sections.join
    [prompt, context]
  end

  def order_document_sections_by_query_similarity(query, contexts)
    query_embedding = get_embedding(query)

    document_similarities = []
    contexts.each do |doc_index, doc_embedding|
      document_similarities.append([vector_similarity(query_embedding, doc_embedding), doc_index])
    end

    document_similarities.sort.reverse
  end

  def get_embedding(text)
    response = @client.embeddings(
      parameters: {
        model: EMBEDDINGS_MODEL,
        input: text
      }
    )
    response.dig('data', 0, 'embedding')
  end

  def vector_similarity(first, second)
    Vector.elements(first.map(&:to_f)).inner_product(Vector.elements(second.map(&:to_f)))
  end
end
