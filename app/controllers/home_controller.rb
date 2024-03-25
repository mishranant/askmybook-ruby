# frozen_string_literal: true

class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:ask]
  before_action :set_default_question, only: %i[index question]

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
      puts "This question has been asked before, this is the answer:\n#{prev_question.answer}"
      prev_question.increment!(:ask_count)
      render json: { question: prev_question.question, answer: prev_question.answer, id: prev_question.id }
    else
      create_and_render_new_question(question)
    end
  end

  private

  def set_default_question
    @default_question = 'What is The Minimalist Entrepreneur about?'
  end

  def create_and_render_new_question(question)
    answer_service = AnswerService.new(question)
    @question = Question.new(question:, **answer_service.generate_answer)
    if @question.save
      render json: { answer: @question.answer, id: @question.id }
    else
      render json: @question.errors, status: :unprocessable_entity
    end
  end
end
# TODO: implement other endpoints?
