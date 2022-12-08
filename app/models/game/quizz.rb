class Game::Quizz
  attr_accessor :room, :broadcaster

  private :room=, :room, :broadcaster=, :broadcaster

  def initialize(room:, broadcaster: Game::Broadcaster)
    @room = room
    @broadcaster = broadcaster.new(destination: @room)
  end

  def enter_room(user:)
    user.connect_to(room)

    broadcaster.send({
      message_type: 'room_info',
      user_count: room.connected_users.count,
      state: room.state,
      message: "Conectado na sala - ESTADO: #{room.state}, CONECTADOS #{room.connected_users.count}"
    })
  end

  def disconnect_from_room(user:)
    user.disconnect_from_room
  end

  def init_game(user:)
    return if user != room.owner

    room.update!(state: :asking_questions, current_question: room.questions[0])

    broadcaster.send({
      message_type: 'init_game',
      room: room.code,
      state: room.state
    })

    broadcaster.send({
      message_type: 'sending_question',
      question: room.current_question,
      alternatives: room.current_question.alternatives
    })
  end

  def register_answer(user:, alternative:)
    return unless room.asking_questions?

    user.answers.create!(room: room, question: room.current_question, alternative: alternative)

    broadcaster.send({
      message_type: 'answer_confirmation',
      message: 'Aswer registred' 
    })

    try_next_question
  end

  def show_current_scoreboard
    broadcaster.send({
      message_type: 'sending_scoreboard',
      scoreboard: room.last_scoreboard
    })
  end

  private

  def try_next_question
    return unless room.current_question_all_answered?

    if room.next_question.present?
      go_next_question
    else
      end_game
    end
  end

  def go_next_question
    room.update(current_question: room.next_question)

    broadcaster.send({
      message_type: 'sending_question',
      question: room.current_question,
      alternatives: room.current_question.alternatives
    })
  end

  def end_game
    room.update(state: :ending, current_question: nil)

    broadcaster.send({
      message_type: 'end_game'
    })
  end
end
