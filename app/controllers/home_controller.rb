class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:ask]

  def index
    @default_question = 'What is The Minimalist Entrepreneur about?'
    @answer = nil
  end

  # todo: add get question/:id

  def ask
    # todo: add the openai query, vector similarity, question history
    @answer = 'filler text'
    @id = 1
    respond_to do |format|
      format.json { render json: { answer: @answer, id: @id } }
    end
  end
end
