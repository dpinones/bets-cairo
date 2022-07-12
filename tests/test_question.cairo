%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.question import Question
from src.question import view_test_count
from src.question import view_question_count
from src.question import view_cuestions
from src.question import view_answers_correct
from src.question import create_test
from src.question import add_question
from src.question import add_correct_answer
from src.question import points

@external
func test_sum{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    # Create a new test
    let (test_id) = create_test()
    let (question_id) = add_question(test_id, 00, 1, 2, 3, 4)
    local array : felt* = new (3)
    add_correct_answer(question_id, 1, array)

    let (count_questions) = view_question_count(test_id)
    assert count_questions = 1

    let (correct) = view_answers_correct(test_id, question_id)
    assert correct = 3

    local array2 : felt* = new (4)
    let(point) = points(test_id, 1, array2)
    assert point = 5
    return ()
end