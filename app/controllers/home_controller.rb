class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:ask]
  before_action :set_default_question, only: [:index, :question]

  def index; end

  def question
    @question = Question.find_by(id: params[:id])
    @answer = @question.answer if @question
    render :index
  end

  def ask
    question = params[:question]
    question += '?' unless question.end_with?('?')

    prev_question = Question.find_by(question:)

    if prev_question
      puts "previously asked and answered: #{prev_question.answer}"
      prev_question.ask_count += 1
      respond_to do |format|
        if prev_question.save
          format.json { render json: { question: prev_question.question, answer: prev_question.answer, id: prev_question.id } }
        else
          format.json { render json: @question.errors, status: :unprocessable_entity }
        end
        return
      end
    end

    @question = Question.new(question:, **AnswerService.new(question).getAnswer)
    respond_to do |format|
      if @question.save
        format.json { render json: { answer: @question.answer, id: @question.id } }
      else
        format.json { render json: @question.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_default_question
    @default_question = 'What is The Minimalist Entrepreneur about?'
  end
end
# TODO: implement other endpoints?
