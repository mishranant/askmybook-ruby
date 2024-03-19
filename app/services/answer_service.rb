class AnswerService
  def initialize(question_text)
    @question_text = question_text
  end

  # TODO: add the openai query, vector similarity
  # df = pd.read_csv('book.pdf.pages.csv')
  # document_embeddings = load_embeddings('book.pdf.embeddings.csv')
  # answer, context = answer_query_with_context(question_asked, df, document_embeddings)
  def call
    answer = 'Baby see'
    context = 'Mai hu South Delhi ki'

    { answer:, context: }
  end
end
