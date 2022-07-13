%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.question import Question
from src.question import view_test_count
from src.question import view_question_count
from src.question import view_questions
# from src.question import view_answers_correct
from src.question import create_test
from src.question import add_question
from src.question import add_correct_answer
from src.question import points
from src.question import _get_answer_for_id
from src.question import view_question

@external
func test_sum{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Create a new test
    let (test_id) = create_test(1)
    let (question_id) = add_question(test_id, 00, 11, 22, 33, 44)
    let (question_id2) = add_question(test_id, 00, 11, 22, 33, 44)

    # local array : felt* = new (3)
    local array : felt* = new (3, 1)
    add_correct_answer(test_id, 2, array)

    let (count_questions) = view_question_count(test_id)
    assert count_questions = 2

    # let (correct) = view_answers_correct(test_id, question_id)
    # assert correct = 3

    let (question : Question) = view_question(0, 0)
    assert question.description = 00
    assert question.optionA = 11
    assert question.optionB = 22
    assert question.optionC = 33
    assert question.optionD = 44
    # obtain the correct answer
    # let (correct_answer) = _get_answer_for_id(question, correct)
    # assert correct_answer = 3

    # local array2 : felt* = new (44)
    local array2 : felt* = new (44, 22)
    let (point) = points(test_id, 2, array2)
    assert point = 10
    return ()
end
