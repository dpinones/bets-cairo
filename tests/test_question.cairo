%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc

from src.question import Question
from src.question import Test
from src.question import view_test_count
from src.question import view_test
from src.question import view_question_count
from src.question import view_questions
from src.question import create_test
from src.question import add_question
from src.question import add_correct_answer
from src.question import send_answer
from src.question import _get_answer_for_id
from src.question import view_question
from src.question import view_count_users_test
from src.question import view_user_test
from src.question import view_points_user_test
from starkware.starknet.common.syscalls import get_caller_address


# @view
# func test_sum{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
#     alloc_locals
#     # Create a new test
#     let (test_id) = create_test(1)
#     let (question_id) = add_question(test_id, 00, 11, 22, 33, 44)
#     let (question_id2) = add_question(test_id, 00, 11, 22, 33, 44)

#     # local array : felt* = new (3)
#     local array : felt* = new (3, 1)
#     add_correct_answer(test_id, 2, array)

#     ready_test(test_id)

#     let (count_questions) = view_question_count(test_id)
#     assert count_questions = 2

#     # let (correct) = view_answers_correct(test_id, question_id)
#     # assert correct = 3

#     let (question : Question) = view_question(0, 0)
#     assert question.description = 00
#     assert question.optionA = 11
#     assert question.optionB = 22
#     assert question.optionC = 33
#     assert question.optionD = 44
#     # obtain the correct answer
#     # let (correct_answer) = _get_answer_for_id(question, correct)
#     # assert correct_answer = 3

#     # local array2 : felt* = new (44)
#     local array2 : felt* = new (3, 1)
#     send_answer(test_id, 2, array2)

#     let (count_users) = view_count_users_test(test_id)
#     assert count_users = 1

#     let (user_test) = view_user_test(0)
#     assert user_test = TRUE
    
#     let (point) = view_points_user_test(test_id)
#     assert point = 10

#     return ()
# end

@external
func test_empty{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (test_count) = view_test_count()
    assert test_count = 0
    return ()
end

@external
func test_question_empty{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (test_id) = create_test(1)
    let (question_count) = view_question_count(test_id)
    assert question_count = 0
    return ()
end

@external
func test_add_question_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (test_id) = create_test(1)
    let (question_id) = add_question(test_id, 00, 11, 22, 33, 44)
    let (question_count) = view_question_count(test_id)
    assert question_count = 1
    return ()
end

@external
func test_add_question_correct{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (test_id) = create_test(1)
    let (question_id) = add_question(test_id, 00, 11, 22, 33, 44)
    let (question: Question) = view_question(test_id, question_id)
    assert question.description = 00
    assert question.optionA = 11
    assert question.optionB = 22
    assert question.optionC = 33
    assert question.optionD = 44
    return ()
end

@external
func test_add_correct_answer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    
    let (test_id) = create_test(1)
    let (question_id) = add_question(test_id, 00, 11, 22, 33, 44)
    
    let (test: Test) = view_test(test_id)
    assert test.open = TRUE
    
    let (local array : felt*) = alloc()
    assert array[0] = 1
    add_correct_answer(test_id, 1, array)
    
    let (test1: Test) = view_test(test_id)
    assert test1.open = FALSE

    return ()
end

@external
func test_send_answer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (test_id) = create_test(1)
    let (question_id) = add_question(test_id, 00, 11, 22, 33, 44)
    let (local array : felt*) = alloc()
    assert array[0] = 1
    add_correct_answer(test_id, 1, array)
    
    let (local array : felt*) = alloc()
    assert array[0] = 1
    send_answer(test_id, 1, array)

    let (points) = view_points_user_test(test_id)
    assert points = 5
    
    return ()
end